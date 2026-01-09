#include <math.h>

// Vector operations
void vec3_normalize(float out[3], const float in[3]) {
    float len = sqrtf(in[0]*in[0] + in[1]*in[1] + in[2]*in[2]);
    if (len > 0.0f) {
        float inv_len = 1.0f / len;
        out[0] = in[0] * inv_len;
        out[1] = in[1] * inv_len;
        out[2] = in[2] * inv_len;
    } else {
        out[0] = 0.0f;
        out[1] = 0.0f;
        out[2] = 0.0f;
    }
}

float vec3_dot(const float a[3], const float b[3]) {
    return a[0]*b[0] + a[1]*b[1] + a[2]*b[2];
}

void vec3_cross(float out[3], const float a[3], const float b[3]) {
    out[0] = a[1]*b[2] - a[2]*b[1];
    out[1] = a[2]*b[0] - a[0]*b[2];
    out[2] = a[0]*b[1] - a[1]*b[0];
}

void vec3_sub(float out[3], const float a[3], const float b[3]) {
    out[0] = a[0] - b[0];
    out[1] = a[1] - b[1];
    out[2] = a[2] - b[2];
}

// Matrix operations
void mat4_identity(float out[4][4]) {
    for (int i = 0; i < 4; i++) {
        for (int j = 0; j < 4; j++) {
            out[i][j] = (i == j) ? 1.0f : 0.0f;
        }
    }
}

void mat4_copy(float out[4][4], const float in[4][4]) {
    for (int i = 0; i < 4; i++) {
        for (int j = 0; j < 4; j++) {
            out[i][j] = in[i][j];
        }
    }
}

void mat4_mul(float out[4][4], const float a[4][4], const float b[4][4]) {
    float temp[4][4];
    for (int i = 0; i < 4; i++) {
        for (int j = 0; j < 4; j++) {
            temp[i][j] = a[i][0] * b[0][j] + a[i][1] * b[1][j] +
                         a[i][2] * b[2][j] + a[i][3] * b[3][j];
        }
    }
    mat4_copy(out, temp);
}

float deg_to_rad(float degrees) {
    return degrees * (float)M_PI / 180.0f;
}

// Rotation matrix (axis-angle)
void mat4_rotate(float out[4][4], const float angle, const float axis[3]) {
    float a = deg_to_rad(angle);
    float c = cosf(a);
    float s = sinf(a);
    
    float norm_axis[3];
    vec3_normalize(norm_axis, axis);
    
    float x = norm_axis[0];
    float y = norm_axis[1];
    float z = norm_axis[2];
    
    float t = 1.0f - c;
    
    float rot[4][4] = {
        {t*x*x + c,    t*x*y - s*z, t*x*z + s*y, 0.0f},
        {t*x*y + s*z,  t*y*y + c,   t*y*z - s*x, 0.0f},
        {t*x*z - s*y,  t*y*z + s*x, t*z*z + c,   0.0f},
        {0.0f,         0.0f,        0.0f,        1.0f}
    };
    
    mat4_mul(out, rot, out);
}

// LookAt matrix
void mat4_lookAt(float out[4][4], const float eye[3], const float center[3], const float up[3]) {
    float f[3], s[3], u[3];
    
    // f = normalize(center - eye)
    vec3_sub(f, center, eye);
    vec3_normalize(f, f);
    
    // s = normalize(cross(f, up))
    vec3_cross(s, f, up);
    vec3_normalize(s, s);
    
    // u = cross(s, f)
    vec3_cross(u, s, f);
    
    float result[4][4] = {
        { s[0], u[0], -f[0], 0.0f },
        { s[1], u[1], -f[1], 0.0f },
        { s[2], u[2], -f[2], 0.0f },
        { -vec3_dot(s, eye), -vec3_dot(u, eye), vec3_dot(f, eye), 1.0f }
    };
    
    mat4_copy(out, result);
}

// Perspective matrix
void mat4_perspective(float out[4][4], float fovy_degrees, float aspect, float near, float far) {
    float f = 1.0f / tanf(deg_to_rad(fovy_degrees) / 2.0f);
    float nf = 1.0f / (near - far);
    
    float result[4][4] = {
        { f/aspect, 0.0f, 0.0f, 0.0f },
        { 0.0f, f, 0.0f, 0.0f },
        { 0.0f, 0.0f, (far + near) * nf, -1.0f },
        { 0.0f, 0.0f, (2.0f * far * near) * nf, 0.0f }
    };
    
    mat4_copy(out, result);
}
