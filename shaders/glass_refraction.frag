#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;
uniform float uRadiusRatio;
uniform sampler2D uBackdrop;
out vec4 fragColor;

void main() {
  vec2 p = FlutterFragCoord().xy;
  vec2 halfSize = uSize * 0.5;
  float radius = min(uRadiusRatio * min(uSize.x, uSize.y), min(halfSize.x, halfSize.y));
  vec2 q = abs(p - halfSize) - (halfSize - vec2(radius));
  float distanceToEdge = length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - radius;
  vec2 normal;
  if (q.x > 0.0 && q.y > 0.0) {
    normal = normalize(max(q, 0.0)) * sign(p - halfSize);
  } else if (q.x > q.y) {
    normal = vec2(sign(p.x - halfSize.x), 0.0);
  } else {
    normal = vec2(0.0, sign(p.y - halfSize.y));
  }
  // A convex droplet pulls the scene toward its centre, then bends it more
  // strongly where the surface curves down to meet the surrounding air.
  float rimWidth = min(uSize.y * 0.42, 24.0);
  float rim = 1.0 - smoothstep(0.0, rimWidth, abs(distanceToEdge));
  vec2 lensPoint = halfSize + (p - halfSize) * 0.91;
  vec2 samplePoint = lensPoint - normal * rim * rim * min(rimWidth * 0.6, 10.0);
  vec2 uv = clamp(samplePoint / uSize, vec2(0.001), vec2(0.999));
#ifdef IMPELLER_TARGET_OPENGLES
  uv.y = 1.0 - uv.y;
#endif
  fragColor = texture(uBackdrop, uv);
}
