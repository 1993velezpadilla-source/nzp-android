#include "iw4native/android_renderer.hpp"
#include "iw4native/sanctum_preview.hpp"

#include <GLES3/gl3.h>
#include <android/log.h>

#include <algorithm>
#include <array>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <span>
#include <string>
#include <sstream>
#include <vector>

namespace iw4native::android {
namespace {

constexpr const char* kTag = "IW4NativeRenderer";
constexpr float kPi = 3.14159265358979323846f;

struct Mat4 {
    float m[16]{};
};

Mat4 identity() {
    Mat4 out{};
    out.m[0] = out.m[5] = out.m[10] = out.m[15] = 1.0f;
    return out;
}

Mat4 multiply(const Mat4& a, const Mat4& b) {
    Mat4 out{};
    for (int col = 0; col < 4; ++col) {
        for (int row = 0; row < 4; ++row) {
            out.m[col * 4 + row] =
                a.m[0 * 4 + row] * b.m[col * 4 + 0] +
                a.m[1 * 4 + row] * b.m[col * 4 + 1] +
                a.m[2 * 4 + row] * b.m[col * 4 + 2] +
                a.m[3 * 4 + row] * b.m[col * 4 + 3];
        }
    }
    return out;
}

Mat4 perspective(float fovYRadians, float aspect, float nearPlane, float farPlane) {
    Mat4 out{};
    const float f = 1.0f / std::tan(fovYRadians * 0.5f);
    out.m[0] = f / aspect;
    out.m[5] = f;
    out.m[10] = (farPlane + nearPlane) / (nearPlane - farPlane);
    out.m[11] = -1.0f;
    out.m[14] = (2.0f * farPlane * nearPlane) / (nearPlane - farPlane);
    return out;
}

struct Vec3 {
    float x;
    float y;
    float z;
};

Vec3 normalize(Vec3 v) {
    const float len = std::sqrt(v.x*v.x + v.y*v.y + v.z*v.z);
    if (len <= 0.00001f) return {0.0f, 0.0f, 0.0f};
    return {v.x/len, v.y/len, v.z/len};
}

Vec3 cross(Vec3 a, Vec3 b) {
    return {
        a.y*b.z - a.z*b.y,
        a.z*b.x - a.x*b.z,
        a.x*b.y - a.y*b.x
    };
}

float dot(Vec3 a, Vec3 b) {
    return a.x*b.x + a.y*b.y + a.z*b.z;
}

std::size_t cameraVisibilityScore(
    std::span<const PreviewVertex> vertices,
    Vec3 eye,
    Vec3 target) {
    const Vec3 forward = normalize({
        target.x - eye.x,
        target.y - eye.y,
        target.z - eye.z
    });

    std::size_t score = 0;
    // One vertex per triangle is sufficient for a fast one-shot visibility
    // probe and avoids spending meaningful startup time on the full 72k verts.
    for (std::size_t i = 0; i < vertices.size(); i += 3) {
        const Vec3 delta{
            vertices[i].x - eye.x,
            vertices[i].y - eye.y,
            vertices[i].z - eye.z
        };
        const float distanceSq = dot(delta, delta);
        if (distanceSq <= 0.01f) continue;

        const float front = dot(delta, forward);
        if (front <= 0.05f) continue;

        // Generous cone: this only rejects geometry clearly behind/off-axis.
        const float cosineSq = (front * front) / distanceSq;
        if (cosineSq >= 0.30f) ++score;
    }
    return score;
}

Mat4 lookAt(Vec3 eye, Vec3 center, Vec3 up) {
    const Vec3 f = normalize({center.x-eye.x, center.y-eye.y, center.z-eye.z});
    const Vec3 s = normalize(cross(f, up));
    const Vec3 u = cross(s, f);

    Mat4 out = identity();
    out.m[0] = s.x;
    out.m[4] = s.y;
    out.m[8] = s.z;

    out.m[1] = u.x;
    out.m[5] = u.y;
    out.m[9] = u.z;

    out.m[2] = -f.x;
    out.m[6] = -f.y;
    out.m[10] = -f.z;

    out.m[12] = -dot(s, eye);
    out.m[13] = -dot(u, eye);
    out.m[14] = dot(f, eye);
    return out;
}

GLuint compileShader(GLenum type, const char* source) {
    const GLuint shader = glCreateShader(type);
    glShaderSource(shader, 1, &source, nullptr);
    glCompileShader(shader);

    GLint ok = GL_FALSE;
    glGetShaderiv(shader, GL_COMPILE_STATUS, &ok);
    if (ok == GL_TRUE) return shader;

    char log[1024]{};
    glGetShaderInfoLog(shader, sizeof(log), nullptr, log);
    __android_log_print(ANDROID_LOG_ERROR, kTag, "shader compile failed: %s", log);
    glDeleteShader(shader);
    return 0;
}

GLuint linkProgram(GLuint vs, GLuint fs) {
    const GLuint program = glCreateProgram();
    glAttachShader(program, vs);
    glAttachShader(program, fs);
    glLinkProgram(program);

    GLint ok = GL_FALSE;
    glGetProgramiv(program, GL_LINK_STATUS, &ok);
    if (ok == GL_TRUE) return program;

    char log[1024]{};
    glGetProgramInfoLog(program, sizeof(log), nullptr, log);
    __android_log_print(ANDROID_LOG_ERROR, kTag, "program link failed: %s", log);
    glDeleteProgram(program);
    return 0;
}

constexpr const char* kVertexShader = R"(
#version 300 es
layout(location=0) in vec3 aPosition;
layout(location=1) in vec3 aColor;
uniform mat4 uMvp;
out vec3 vColor;
void main() {
    vColor = aColor;
    gl_Position = uMvp * vec4(aPosition, 1.0);
}
)";

constexpr const char* kFragmentShader = R"(
#version 300 es
precision mediump float;
in vec3 vColor;
out vec4 outColor;
void main() {
    float fog = clamp(gl_FragCoord.z * 0.65, 0.0, 0.62);
    vec3 c = mix(vColor, vec3(0.025, 0.028, 0.032), fog);
    outColor = vec4(c, 1.0);
}
)";

struct Vertex {
    float x, y, z;
    float r, g, b;
};

constexpr std::array<Vertex, 150> kRoom = {{
    // floor, 2 triangles
    {-8,-1,-10, .16f,.16f,.17f},{ 8,-1,-10, .16f,.16f,.17f},{ 8,-1, 10, .22f,.22f,.23f},
    {-8,-1,-10, .16f,.16f,.17f},{ 8,-1, 10, .22f,.22f,.23f},{-8,-1, 10, .22f,.22f,.23f},
    // ceiling
    {-8,5,-10, .08f,.08f,.09f},{ 8,5, 10, .10f,.10f,.11f},{ 8,5,-10, .08f,.08f,.09f},
    {-8,5,-10, .08f,.08f,.09f},{-8,5, 10, .10f,.10f,.11f},{ 8,5, 10, .10f,.10f,.11f},
    // back wall
    {-8,-1,-10, .20f,.18f,.16f},{ 8,5,-10, .28f,.24f,.20f},{ 8,-1,-10, .20f,.18f,.16f},
    {-8,-1,-10, .20f,.18f,.16f},{-8,5,-10, .28f,.24f,.20f},{ 8,5,-10, .28f,.24f,.20f},
    // left wall
    {-8,-1,-10, .15f,.14f,.13f},{-8,-1, 10, .21f,.19f,.17f},{-8,5, 10, .25f,.22f,.18f},
    {-8,-1,-10, .15f,.14f,.13f},{-8,5, 10, .25f,.22f,.18f},{-8,5,-10, .20f,.18f,.15f},
    // right wall
    {8,-1,-10, .15f,.14f,.13f},{8,5,10, .25f,.22f,.18f},{8,-1,10, .21f,.19f,.17f},
    {8,-1,-10, .15f,.14f,.13f},{8,5,-10, .20f,.18f,.15f},{8,5,10, .25f,.22f,.18f},

    // central altar block front/back/left/right/top
    {-1.6f,-1,-3.5f,.30f,.27f,.24f},{1.6f,-1,-3.5f,.30f,.27f,.24f},{1.6f,0.5f,-3.5f,.38f,.34f,.30f},
    {-1.6f,-1,-3.5f,.30f,.27f,.24f},{1.6f,0.5f,-3.5f,.38f,.34f,.30f},{-1.6f,0.5f,-3.5f,.38f,.34f,.30f},
    {-1.6f,-1,-5.2f,.23f,.21f,.19f},{1.6f,0.5f,-5.2f,.33f,.29f,.25f},{1.6f,-1,-5.2f,.23f,.21f,.19f},
    {-1.6f,-1,-5.2f,.23f,.21f,.19f},{-1.6f,0.5f,-5.2f,.33f,.29f,.25f},{1.6f,0.5f,-5.2f,.33f,.29f,.25f},
    {-1.6f,-1,-5.2f,.24f,.22f,.19f},{-1.6f,-1,-3.5f,.30f,.27f,.24f},{-1.6f,0.5f,-3.5f,.38f,.34f,.30f},
    {-1.6f,-1,-5.2f,.24f,.22f,.19f},{-1.6f,0.5f,-3.5f,.38f,.34f,.30f},{-1.6f,0.5f,-5.2f,.32f,.28f,.24f},
    {1.6f,-1,-5.2f,.24f,.22f,.19f},{1.6f,0.5f,-3.5f,.38f,.34f,.30f},{1.6f,-1,-3.5f,.30f,.27f,.24f},
    {1.6f,-1,-5.2f,.24f,.22f,.19f},{1.6f,0.5f,-5.2f,.32f,.28f,.24f},{1.6f,0.5f,-3.5f,.38f,.34f,.30f},
    {-1.6f,0.5f,-5.2f,.32f,.28f,.24f},{-1.6f,0.5f,-3.5f,.38f,.34f,.30f},{1.6f,0.5f,-3.5f,.38f,.34f,.30f},
    {-1.6f,0.5f,-5.2f,.32f,.28f,.24f},{1.6f,0.5f,-3.5f,.38f,.34f,.30f},{1.6f,0.5f,-5.2f,.32f,.28f,.24f},

    // left pillar
    {-5,-1,-1,.25f,.23f,.21f},{-4,-1,-1,.25f,.23f,.21f},{-4,4,-1,.34f,.31f,.27f},
    {-5,-1,-1,.25f,.23f,.21f},{-4,4,-1,.34f,.31f,.27f},{-5,4,-1,.34f,.31f,.27f},
    {-5,-1,-2,.20f,.19f,.17f},{-4,4,-2,.30f,.27f,.23f},{-4,-1,-2,.20f,.19f,.17f},
    {-5,-1,-2,.20f,.19f,.17f},{-5,4,-2,.30f,.27f,.23f},{-4,4,-2,.30f,.27f,.23f},
    {-5,-1,-2,.20f,.19f,.17f},{-5,-1,-1,.25f,.23f,.21f},{-5,4,-1,.34f,.31f,.27f},
    {-5,-1,-2,.20f,.19f,.17f},{-5,4,-1,.34f,.31f,.27f},{-5,4,-2,.30f,.27f,.23f},
    {-4,-1,-2,.20f,.19f,.17f},{-4,4,-1,.34f,.31f,.27f},{-4,-1,-1,.25f,.23f,.21f},
    {-4,-1,-2,.20f,.19f,.17f},{-4,4,-2,.30f,.27f,.23f},{-4,4,-1,.34f,.31f,.27f},

    // right pillar
    {4,-1,-1,.25f,.23f,.21f},{5,-1,-1,.25f,.23f,.21f},{5,4,-1,.34f,.31f,.27f},
    {4,-1,-1,.25f,.23f,.21f},{5,4,-1,.34f,.31f,.27f},{4,4,-1,.34f,.31f,.27f},
    {4,-1,-2,.20f,.19f,.17f},{5,4,-2,.30f,.27f,.23f},{5,-1,-2,.20f,.19f,.17f},
    {4,-1,-2,.20f,.19f,.17f},{4,4,-2,.30f,.27f,.23f},{5,4,-2,.30f,.27f,.23f},
    {4,-1,-2,.20f,.19f,.17f},{4,-1,-1,.25f,.23f,.21f},{4,4,-1,.34f,.31f,.27f},
    {4,-1,-2,.20f,.19f,.17f},{4,4,-1,.34f,.31f,.27f},{4,4,-2,.30f,.27f,.23f},
    {5,-1,-2,.20f,.19f,.17f},{5,4,-1,.34f,.31f,.27f},{5,-1,-1,.25f,.23f,.21f},
    {5,-1,-2,.20f,.19f,.17f},{5,4,-2,.30f,.27f,.23f},{5,4,-1,.34f,.31f,.27f},

    // far doorway trim left/right/top
    {-3,-1,8,.16f,.15f,.14f},{-2.3f,-1,8,.16f,.15f,.14f},{-2.3f,3.8f,8,.24f,.22f,.19f},
    {-3,-1,8,.16f,.15f,.14f},{-2.3f,3.8f,8,.24f,.22f,.19f},{-3,3.8f,8,.24f,.22f,.19f},
    {2.3f,-1,8,.16f,.15f,.14f},{3,-1,8,.16f,.15f,.14f},{3,3.8f,8,.24f,.22f,.19f},
    {2.3f,-1,8,.16f,.15f,.14f},{3,3.8f,8,.24f,.22f,.19f},{2.3f,3.8f,8,.24f,.22f,.19f},
    {-3,3.1f,8,.18f,.17f,.15f},{3,3.1f,8,.18f,.17f,.15f},{3,3.8f,8,.24f,.22f,.19f},
    {-3,3.1f,8,.18f,.17f,.15f},{3,3.8f,8,.24f,.22f,.19f},{-3,3.8f,8,.24f,.22f,.19f},

    // floor aisle strips
    {-1.1f,-0.99f,-10,.42f,.36f,.25f},{-0.85f,-0.99f,-10,.42f,.36f,.25f},{-0.85f,-0.99f,10,.35f,.30f,.22f},
    {-1.1f,-0.99f,-10,.42f,.36f,.25f},{-0.85f,-0.99f,10,.35f,.30f,.22f},{-1.1f,-0.99f,10,.35f,.30f,.22f},
    {0.85f,-0.99f,-10,.42f,.36f,.25f},{1.1f,-0.99f,-10,.42f,.36f,.25f},{1.1f,-0.99f,10,.35f,.30f,.22f},
    {0.85f,-0.99f,-10,.42f,.36f,.25f},{1.1f,-0.99f,10,.35f,.30f,.22f},{0.85f,-0.99f,10,.35f,.30f,.22f},

    // cross-like marker on back wall
    {-0.12f,1.0f,-9.96f,.55f,.42f,.20f},{0.12f,1.0f,-9.96f,.55f,.42f,.20f},{0.12f,3.6f,-9.96f,.68f,.52f,.25f},
    {-0.12f,1.0f,-9.96f,.55f,.42f,.20f},{0.12f,3.6f,-9.96f,.68f,.52f,.25f},{-0.12f,3.6f,-9.96f,.68f,.52f,.25f},
    {-0.8f,2.5f,-9.95f,.60f,.46f,.22f},{0.8f,2.5f,-9.95f,.60f,.46f,.22f},{0.8f,2.75f,-9.95f,.70f,.55f,.27f},
    {-0.8f,2.5f,-9.95f,.60f,.46f,.22f},{0.8f,2.75f,-9.95f,.70f,.55f,.27f},{-0.8f,2.75f,-9.95f,.70f,.55f,.27f}
}};

GLuint gProgram = 0;
GLuint gVao = 0;
GLuint gVbo = 0;
GLuint gSanctumVao = 0;
GLuint gSanctumVbo = 0;
GLsizei gSanctumVertexCount = 0;
PreviewSceneInfo gSanctumScene{};
bool gSanctumLoaded = false;
std::size_t gCameraCandidate = 0;
std::size_t gCameraVisibilityScore = 0;
GLenum gLastGlError = GL_NO_ERROR;
GLint gMvp = -1;
int gWidth = 1;
int gHeight = 1;

float gPlayerX = 0.0f;
float gPlayerY = 0.0f;
float gPlayerZ = 5.2f;
float gYaw = 0.0f;
float gPitch = 0.0f;
float gJumpPhase = 0.0f;
bool gReady = false;

} // namespace

bool rendererInit() {
    rendererShutdown();

    const GLuint vs = compileShader(GL_VERTEX_SHADER, kVertexShader);
    const GLuint fs = compileShader(GL_FRAGMENT_SHADER, kFragmentShader);
    if (!vs || !fs) {
        if (vs) glDeleteShader(vs);
        if (fs) glDeleteShader(fs);
        return false;
    }

    gProgram = linkProgram(vs, fs);
    glDeleteShader(vs);
    glDeleteShader(fs);
    if (!gProgram) return false;

    gMvp = glGetUniformLocation(gProgram, "uMvp");
    if (gMvp < 0) {
        rendererShutdown();
        return false;
    }

    glGenVertexArrays(1, &gVao);
    glGenBuffers(1, &gVbo);
    glBindVertexArray(gVao);
    glBindBuffer(GL_ARRAY_BUFFER, gVbo);
    glBufferData(GL_ARRAY_BUFFER,
                 static_cast<GLsizeiptr>(sizeof(kRoom)),
                 kRoom.data(),
                 GL_STATIC_DRAW);

    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), nullptr);
    glEnableVertexAttribArray(0);
    glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex),
                          reinterpret_cast<const void*>(3 * sizeof(float)));
    glEnableVertexAttribArray(1);

    glBindVertexArray(0);

    glEnable(GL_DEPTH_TEST);
    glDepthFunc(GL_LEQUAL);
    glDisable(GL_CULL_FACE);

    gPlayerX = 0.0f;
    gPlayerY = 0.62f;
    gPlayerZ = 5.2f;
    gYaw = 0.0f;
    gPitch = 0.0f;
    gJumpPhase = 0.0f;
    gReady = true;

    __android_log_print(ANDROID_LOG_INFO, kTag,
                        "GLES3 test-world renderer initialized");
    return true;
}

bool rendererLoadSanctum(const std::byte* data, std::size_t size) {
    if (!gReady || data == nullptr || size == 0) return false;

    std::vector<PreviewVertex> vertices;
    PreviewSceneInfo scene;
    std::string error;
    if (!decodeSanctumPreview(
            std::span<const std::byte>(data, size),
            vertices,
            scene,
            &error)) {
        __android_log_print(
            ANDROID_LOG_ERROR,
            kTag,
            "Sanctum preview decode failed: %s",
            error.c_str());
        return false;
    }

    if (gSanctumVbo) glDeleteBuffers(1, &gSanctumVbo);
    if (gSanctumVao) glDeleteVertexArrays(1, &gSanctumVao);
    gSanctumVbo = 0;
    gSanctumVao = 0;

    glGenVertexArrays(1, &gSanctumVao);
    glGenBuffers(1, &gSanctumVbo);
    glBindVertexArray(gSanctumVao);
    glBindBuffer(GL_ARRAY_BUFFER, gSanctumVbo);
    glBufferData(
        GL_ARRAY_BUFFER,
        static_cast<GLsizeiptr>(vertices.size() * sizeof(PreviewVertex)),
        vertices.data(),
        GL_STATIC_DRAW);
    gLastGlError = glGetError();
    if (gLastGlError != GL_NO_ERROR) {
        __android_log_print(
            ANDROID_LOG_ERROR,
            kTag,
            "Sanctum VBO upload failed: glError=0x%x",
            static_cast<unsigned>(gLastGlError));
        gSanctumLoaded = false;
        glBindVertexArray(0);
        return false;
    }

    glVertexAttribPointer(
        0, 3, GL_FLOAT, GL_FALSE, sizeof(PreviewVertex), nullptr);
    glEnableVertexAttribArray(0);
    glVertexAttribPointer(
        1, 3, GL_FLOAT, GL_FALSE, sizeof(PreviewVertex),
        reinterpret_cast<const void*>(3 * sizeof(float)));
    glEnableVertexAttribArray(1);
    glBindVertexArray(0);

    gSanctumVertexCount = static_cast<GLsizei>(vertices.size());
    gSanctumScene = scene;
    gSanctumLoaded = gSanctumVertexCount > 0;

    const auto& bounds = scene.bounds;

    // A scan's axis-aligned center can be empty space, and an edge-derived
    // spawn can also land behind disconnected photogrammetry fragments.
    // Score several sane camera candidates against the decoded triangles and
    // choose the one that actually sees the most map geometry.
    const float centerX = (bounds.minX + bounds.maxX) * 0.5f;
    const float centerZ = (bounds.minZ + bounds.maxZ) * 0.5f;
    const float widthX = bounds.maxX - bounds.minX;
    const float depthZ = bounds.maxZ - bounds.minZ;
    const Vec3 look{scene.lookX, scene.lookY, scene.lookZ};

    const std::array<Vec3, 7> cameraCandidates{{
        {scene.spawnX, scene.spawnY, scene.spawnZ},
        {centerX + widthX * 0.16f, scene.spawnY, centerZ},
        {centerX - widthX * 0.16f, scene.spawnY, centerZ},
        {centerX, scene.spawnY, centerZ + depthZ * 0.16f},
        {centerX, scene.spawnY, centerZ - depthZ * 0.16f},
        {centerX + widthX * 0.28f, scene.spawnY, centerZ},
        {centerX, scene.spawnY, centerZ + depthZ * 0.28f}
    }};

    std::size_t bestCamera = 0;
    std::size_t bestScore = cameraVisibilityScore(vertices, cameraCandidates[0], look);
    for (std::size_t i = 1; i < cameraCandidates.size(); ++i) {
        const std::size_t score =
            cameraVisibilityScore(vertices, cameraCandidates[i], look);
        if (score > bestScore) {
            bestScore = score;
            bestCamera = i;
        }
    }

    gCameraCandidate = bestCamera;
    gCameraVisibilityScore = bestScore;

    gPlayerX = cameraCandidates[bestCamera].x;
    gPlayerY = cameraCandidates[bestCamera].y;
    gPlayerZ = cameraCandidates[bestCamera].z;

    const float lookX = look.x;
    const float lookY = look.y;
    const float lookZ = look.z;

    const float dx = lookX - gPlayerX;
    const float dy = lookY - gPlayerY;
    const float dz = lookZ - gPlayerZ;
    const float horizontal = std::sqrt(dx * dx + dz * dz);
    gYaw = std::atan2(-dx, -dz);
    gPitch = std::atan2(dy, std::max(horizontal, 0.0001f));
    gJumpPhase = 0.0f;

    __android_log_print(
        ANDROID_LOG_INFO,
        kTag,
        "Sanctum preview loaded: %d vertices, bounds=(%.2f %.2f %.2f)-(%.2f %.2f %.2f) camera[%zu score=%zu]=(%.2f %.2f %.2f) look=(%.2f %.2f %.2f)",
        gSanctumVertexCount,
        bounds.minX, bounds.minY, bounds.minZ,
        bounds.maxX, bounds.maxY, bounds.maxZ,
        bestCamera, bestScore,
        gPlayerX, gPlayerY, gPlayerZ,
        lookX, lookY, lookZ);

    return gSanctumLoaded;
}

std::string rendererDiagnostic() {
    std::ostringstream out;
    out << (gReady ? "GL READY" : "GL NOT READY");
    out << " • " << (gSanctumLoaded ? "SANCTUM GPU PASS" : "SANCTUM GPU FAIL");
    out << " • vertices=" << gSanctumVertexCount;
    out << " • camera=" << gCameraCandidate;
    out << " • visible=" << gCameraVisibilityScore;
    out << " • gl=0x" << std::hex << static_cast<unsigned>(gLastGlError);
    return out.str();
}

void rendererResize(int width, int height) {
    gWidth = std::max(width, 1);
    gHeight = std::max(height, 1);
    glViewport(0, 0, gWidth, gHeight);
}

void rendererFrame(float moveX,
                   float moveY,
                   float lookDeltaX,
                   float lookDeltaY,
                   bool firePressed,
                   bool adsPressed,
                   bool jumpPressed,
                   bool reloadPressed,
                   bool usePressed,
                   bool knifePressed,
                   bool grenadePressed,
                   bool slidePressed,
                   bool pausePressed) {
    if (!gReady) return;

    const float moveSpeed = slidePressed ? 0.135f : 0.085f;
    constexpr float lookSpeed = 0.0036f;

    if (pausePressed) {
        moveX = 0.0f;
        moveY = 0.0f;
        lookDeltaX = 0.0f;
        lookDeltaY = 0.0f;
    }

    gYaw -= lookDeltaX * lookSpeed;
    gPitch -= lookDeltaY * lookSpeed;
    gPitch = std::clamp(gPitch, -1.15f, 1.15f);

    const float sy = std::sin(gYaw);
    const float cy = std::cos(gYaw);
    const float forwardX = -sy;
    const float forwardZ = -cy;
    const float rightX = cy;
    const float rightZ = -sy;

    gPlayerX += (rightX * moveX + forwardX * -moveY) * moveSpeed;
    gPlayerZ += (rightZ * moveX + forwardZ * -moveY) * moveSpeed;

    if (gSanctumLoaded) {
        const float padX = std::min(0.75f, (gSanctumScene.bounds.maxX - gSanctumScene.bounds.minX) * 0.05f);
        const float padZ = std::min(0.75f, (gSanctumScene.bounds.maxZ - gSanctumScene.bounds.minZ) * 0.05f);
        gPlayerX = std::clamp(
            gPlayerX,
            gSanctumScene.bounds.minX + padX,
            gSanctumScene.bounds.maxX - padX);
        gPlayerZ = std::clamp(
            gPlayerZ,
            gSanctumScene.bounds.minZ + padZ,
            gSanctumScene.bounds.maxZ - padZ);
    } else {
        gPlayerX = std::clamp(gPlayerX, -7.2f, 7.2f);
        gPlayerZ = std::clamp(gPlayerZ, -9.2f, 9.2f);
    }

    if (jumpPressed && gJumpPhase <= 0.0f) gJumpPhase = 1.0f;
    float jumpHeight = 0.0f;
    if (gJumpPhase > 0.0f) {
        const float t = 1.0f - gJumpPhase;
        jumpHeight = std::sin(t * kPi) * 0.65f;
        gJumpPhase -= 0.045f;
        if (gJumpPhase < 0.0f) gJumpPhase = 0.0f;
    }

    const float fov = adsPressed ? 52.0f : 72.0f;
    const float aspect = static_cast<float>(gWidth) / static_cast<float>(gHeight);

    const float stanceOffset = slidePressed ? -0.52f : 0.0f;
    const Vec3 eye{gPlayerX, gPlayerY + jumpHeight + stanceOffset, gPlayerZ};
    const Vec3 dir{
        -std::sin(gYaw) * std::cos(gPitch),
        std::sin(gPitch),
        -std::cos(gYaw) * std::cos(gPitch)
    };
    const Vec3 center{eye.x + dir.x, eye.y + dir.y, eye.z + dir.z};

    const Mat4 view = lookAt(eye, center, {0.0f, 1.0f, 0.0f});
    const Mat4 proj = perspective(
        fov * kPi / 180.0f,
        aspect,
        0.08f,
        gSanctumLoaded ? 180.0f : 80.0f);
    const Mat4 mvp = multiply(proj, view);

    if (pausePressed) {
        glClearColor(0.010f, 0.010f, 0.012f, 1.0f);
    } else if (firePressed) {
        glClearColor(0.085f, 0.020f, 0.015f, 1.0f);
    } else if (grenadePressed) {
        glClearColor(0.050f, 0.055f, 0.018f, 1.0f);
    } else if (knifePressed) {
        glClearColor(0.050f, 0.018f, 0.055f, 1.0f);
    } else if (reloadPressed || usePressed) {
        glClearColor(0.020f, 0.038f, 0.052f, 1.0f);
    } else if (gSanctumLoaded) {
        // Deliberately non-black so an on-device screenshot immediately tells
        // us that the GL loop is alive even before textured lighting lands.
        glClearColor(0.070f, 0.085f, 0.105f, 1.0f);
    } else {
        // Fallback room should never present as a silent black screen.
        glClearColor(0.110f, 0.035f, 0.030f, 1.0f);
    }
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

    glUseProgram(gProgram);
    glUniformMatrix4fv(gMvp, 1, GL_FALSE, mvp.m);
    if (gSanctumLoaded) {
        glBindVertexArray(gSanctumVao);
        glDrawArrays(GL_TRIANGLES, 0, gSanctumVertexCount);
    } else {
        glBindVertexArray(gVao);
        glDrawArrays(GL_TRIANGLES, 0, static_cast<GLsizei>(kRoom.size()));
    }
    glBindVertexArray(0);

    const GLenum frameError = glGetError();
    if (frameError != GL_NO_ERROR) {
        gLastGlError = frameError;
    }
}

void rendererShutdown() {
    if (gSanctumVbo) glDeleteBuffers(1, &gSanctumVbo);
    if (gSanctumVao) glDeleteVertexArrays(1, &gSanctumVao);
    if (gVbo) glDeleteBuffers(1, &gVbo);
    if (gVao) glDeleteVertexArrays(1, &gVao);
    if (gProgram) glDeleteProgram(gProgram);
    gSanctumVbo = 0;
    gSanctumVao = 0;
    gSanctumVertexCount = 0;
    gSanctumScene = {};
    gSanctumLoaded = false;
    gCameraCandidate = 0;
    gCameraVisibilityScore = 0;
    gLastGlError = GL_NO_ERROR;
    gVbo = 0;
    gVao = 0;
    gProgram = 0;
    gMvp = -1;
    gReady = false;
}

} // namespace iw4native::android
