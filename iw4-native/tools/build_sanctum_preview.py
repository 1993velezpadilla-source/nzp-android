#!/usr/bin/env python3
"""Build a compact, attribution-preserving Sanctum preview for the native Android probe.

Input is the CC BY St Giles Cripplegate scan by artfletch, fetched through
Objaverse using the same UID already used by the Xziel Sanctum pipeline.

Output format SNP1 v2:
  4s  magic
  u32 version
  u32 triangle_count
  6xf32 global bounds (min xyz, max xyz)
  3xf32 player spawn (xyz)
  3xf32 look target (xyz)
  triangle_count records:
      9xu16 quantized xyz for three vertices
      u16 RGB565 material color

This file intentionally contains geometry + spawn metadata only. Textures are a later gate.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import struct
from pathlib import Path

import numpy as np
import objaverse
import trimesh


UID = "b92917ff83914adc8bc93959ba8b4399"
SOURCE_PAGE = "https://sketchfab.com/3d-models/st-giles-cripplegate-b92917ff83914adc8bc93959ba8b4399"


def load_source(cache_dir: Path) -> Path:
    cache_dir.mkdir(parents=True, exist_ok=True)

    annotations = objaverse.load_annotations([UID])
    annotation = annotations.get(UID)
    if not annotation:
        raise RuntimeError("Sanctum source UID missing from Objaverse annotations")
    if annotation.get("license") != "by":
        raise RuntimeError(
            f"Unexpected Sanctum source license {annotation.get('license')!r}; expected CC BY"
        )

    (cache_dir / "source_metadata.json").write_text(
        json.dumps(annotation, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )

    objects = objaverse.load_objects([UID], download_processes=1)
    source = objects.get(UID)
    if not source:
        raise RuntimeError("Objaverse metadata exists but the GLB could not be downloaded")

    return Path(source)


def iter_world_meshes(scene: trimesh.Scene):
    for node_name in scene.graph.nodes_geometry:
        transform, geom_name = scene.graph[node_name]
        geometry = scene.geometry.get(geom_name)
        if geometry is None or not isinstance(geometry, trimesh.Trimesh):
            continue
        if len(geometry.vertices) == 0 or len(geometry.faces) == 0:
            continue

        mesh = geometry.copy()
        mesh.apply_transform(transform)
        yield node_name, geom_name, mesh


def material_color(name: str, ordinal: int) -> int:
    digest = hashlib.sha1(name.encode("utf-8", errors="replace")).digest()
    base = 130 + digest[0] % 45
    warm = digest[1] % 24 - 12

    r = max(70, min(220, base + warm + 8))
    g = max(70, min(210, base + warm))
    b = max(70, min(200, base - 8))

    if ordinal % 17 == 0:
        r = min(220, r + 28)
        g = min(190, g + 14)
        b = max(70, b - 18)

    r5 = round(r * 31 / 255)
    g6 = round(g * 63 / 255)
    b5 = round(b * 31 / 255)
    return (r5 << 11) | (g6 << 5) | b5


def allocate_quotas(face_counts: list[int], target: int) -> list[int]:
    total = sum(face_counts)
    if total <= 0:
        raise RuntimeError("Sanctum scene contains no triangles")

    target = max(len(face_counts), min(target, total))
    quotas = [max(1, int(round(target * count / total))) for count in face_counts]
    diff = target - sum(quotas)
    order = sorted(range(len(face_counts)), key=lambda i: face_counts[i], reverse=True)

    cursor = 0
    while diff:
        i = order[cursor % len(order)]
        if diff > 0:
            quotas[i] += 1
            diff -= 1
        elif quotas[i] > 1:
            quotas[i] -= 1
            diff += 1
        cursor += 1

    return quotas


def dominant_floor_y(meshes) -> float:
    # GLTF/GLB is Y-up. Accumulate area of upward-facing triangles into 25 cm
    # floor bands, mirroring the dominant-floor logic from the original
    # Sanctum Blender pipeline while avoiding its Z-up conversion.
    buckets: dict[float, float] = {}

    for _node, _name, mesh in meshes:
        vertices = np.asarray(mesh.vertices, dtype=np.float64)
        faces = np.asarray(mesh.faces, dtype=np.int64)
        if len(faces) == 0:
            continue

        stride = max(1, len(faces) // 30000)
        sampled = faces[::stride]
        tri = vertices[sampled]

        e1 = tri[:, 1] - tri[:, 0]
        e2 = tri[:, 2] - tri[:, 0]
        normals = np.cross(e1, e2)
        lengths = np.linalg.norm(normals, axis=1)

        valid = lengths > 1e-10
        if not np.any(valid):
            continue

        normals[valid] /= lengths[valid, None]
        areas = lengths * 0.5 * stride
        centers_y = tri.mean(axis=1)[:, 1]

        upward = valid & (normals[:, 1] > 0.58)
        for y, area in zip(centers_y[upward], areas[upward]):
            band = round(float(y) * 4.0) / 4.0
            buckets[band] = buckets.get(band, 0.0) + float(area)

    if not buckets:
        raise RuntimeError("Could not identify an upward-facing Sanctum floor band")

    # Very low disconnected scan fragments can have large area. Prefer a
    # strong floor band near the middle/lower-middle of the vertical content,
    # not the absolute minimum.
    ranked = sorted(buckets.items(), key=lambda item: item[1], reverse=True)
    strongest_area = ranked[0][1]
    candidates = [item for item in ranked if item[1] >= strongest_area * 0.20]
    return max(candidates, key=lambda item: item[1])[0]


def build_spawn(global_min: np.ndarray,
                global_max: np.ndarray,
                floor_y: float) -> tuple[np.ndarray, np.ndarray]:
    center = (global_min + global_max) * 0.5
    width_x = global_max[0] - global_min[0]
    depth_z = global_max[2] - global_min[2]

    # Spawn near the farther captured edge and look toward the church center.
    # Choosing the longer horizontal axis gives more exterior clearance.
    if depth_z >= width_x:
        spawn = np.array([
            center[0],
            floor_y + 1.70,
            global_max[2] - max(1.5, depth_z * 0.04),
        ], dtype=np.float64)
    else:
        spawn = np.array([
            global_max[0] - max(1.5, width_x * 0.04),
            floor_y + 1.70,
            center[2],
        ], dtype=np.float64)

    look = np.array([
        center[0],
        floor_y + 2.10,
        center[2],
    ], dtype=np.float64)

    return spawn, look


def build_preview(source: Path, out_path: Path, target_triangles: int) -> dict:
    loaded = trimesh.load(source, force="scene", process=False)
    scene = loaded if isinstance(loaded, trimesh.Scene) else trimesh.Scene(loaded)

    meshes = list(iter_world_meshes(scene))
    if not meshes:
        raise RuntimeError("No renderable mesh geometry found in Sanctum source")

    global_min = np.array([np.inf, np.inf, np.inf], dtype=np.float64)
    global_max = np.array([-np.inf, -np.inf, -np.inf], dtype=np.float64)
    face_counts: list[int] = []

    for _node, _name, mesh in meshes:
        bounds = np.asarray(mesh.bounds, dtype=np.float64)
        global_min = np.minimum(global_min, bounds[0])
        global_max = np.maximum(global_max, bounds[1])
        face_counts.append(int(len(mesh.faces)))

    floor_y = dominant_floor_y(meshes)
    spawn, look_target = build_spawn(global_min, global_max, floor_y)

    quotas = allocate_quotas(face_counts, target_triangles)
    span = global_max - global_min
    span[span == 0.0] = 1.0

    out_path.parent.mkdir(parents=True, exist_ok=True)
    selected_total = 0

    with out_path.open("wb") as out:
        out.write(b"SNP1")
        out.write(struct.pack("<I", 2))
        out.write(struct.pack("<I", sum(quotas)))
        out.write(struct.pack("<6f", *(global_min.tolist() + global_max.tolist())))
        out.write(struct.pack("<3f", *spawn.tolist()))
        out.write(struct.pack("<3f", *look_target.tolist()))

        for ordinal, ((node_name, geom_name, mesh), quota) in enumerate(zip(meshes, quotas)):
            face_count = len(mesh.faces)
            if quota >= face_count:
                sample = np.arange(face_count, dtype=np.int64)
            else:
                sample = np.linspace(
                    0,
                    face_count - 1,
                    num=quota,
                    endpoint=True,
                    dtype=np.int64,
                )

            color = material_color(f"{node_name}:{geom_name}", ordinal)
            vertices = np.asarray(mesh.vertices, dtype=np.float64)
            faces = np.asarray(mesh.faces, dtype=np.int64)

            for face_index in sample:
                tri = vertices[faces[face_index]]
                normalized = np.clip((tri - global_min) / span, 0.0, 1.0)
                quantized = np.rint(normalized * 65535.0).astype(np.uint16).reshape(-1)
                out.write(struct.pack("<9HH", *(int(v) for v in quantized), color))
                selected_total += 1

    if selected_total != sum(quotas):
        raise RuntimeError(
            f"Preview triangle count mismatch: wrote {selected_total}, expected {sum(quotas)}"
        )

    return {
        "schema": 1,
        "format": "SNP1",
        "sourceUid": UID,
        "sourcePage": SOURCE_PAGE,
        "sourceAuthor": "artfletch",
        "sourceLicense": "CC BY",
        "sourceMeshes": len(meshes),
        "sourceTriangles": sum(face_counts),
        "previewTriangles": selected_total,
        "boundsMin": global_min.tolist(),
        "boundsMax": global_max.tolist(),
        "dominantFloorY": floor_y,
        "playerSpawn": spawn.tolist(),
        "lookTarget": look_target.tolist(),
        "outputBytes": out_path.stat().st_size,
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--cache-dir", type=Path, required=True)
    parser.add_argument("--out", type=Path, required=True)
    parser.add_argument("--report", type=Path, required=True)
    parser.add_argument("--target-triangles", type=int, default=24000)
    args = parser.parse_args()

    source = load_source(args.cache_dir)
    report = build_preview(source, args.out, args.target_triangles)

    args.report.parent.mkdir(parents=True, exist_ok=True)
    args.report.write_text(
        json.dumps(report, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )

    attribution = args.out.parent / "SANCTUM_ATTRIBUTION.txt"
    attribution.write_text(
        "Sanctum native preview geometry\n"
        "St Giles Cripplegate by artfletch\n"
        f"Original Sketchfab UID: {UID}\n"
        f"Original page: {SOURCE_PAGE}\n"
        "License published by creator: Creative Commons Attribution (CC BY).\n"
        "Downloaded for this build through the public Objaverse dataset mirror.\n",
        encoding="utf-8",
    )

    print(json.dumps(report, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
