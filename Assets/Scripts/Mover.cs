using UnityEngine;

public static class DistanceFunction
{
    public static Vector3 Max(Vector3 posA, Vector3 posB)
    {
        return new Vector3(
            Mathf.Max(posA.x, posB.x),
            Mathf.Max(posA.y, posB.y),
            Mathf.Max(posA.z, posB.z));
    }

    public static Vector3 Abs(Vector3 pos)
    {
        return new Vector3(
            Mathf.Abs(pos.x),
            Mathf.Abs(pos.y),
            Mathf.Abs(pos.z));
    }

    public static Vector3 Frac(Vector3 pos)
    {
        return new Vector3(
            pos.x - Mathf.Floor(pos.x),
            pos.y - Mathf.Floor(pos.y),
            pos.z - Mathf.Floor(pos.z));
    }

    public static Vector3 Divide(Vector3 a, Vector3 b)
    {
        return new Vector3(a.x / b.x, a.y / b.x, a.z / b.z);
    }

    public static Vector3 Multiply(Vector3 a, Vector3 b)
    {
        return new Vector3(a.x * b.x, a.y * b.x, a.z * b.z);
    }

    public static Vector3 Mod(Vector3 pos, Vector3 span)
    {
        return Multiply(Frac(Abs(Divide(pos, span))), Abs(span));
    }

    public static Vector3 Repeat(Vector3 pos, Vector3 span)
    {
        return Mod(pos, span) - span * 0.5f;
    }

    public static float RoundBox(Vector3 pos, float size, float round)
    {
        return Max(Abs(pos) - Vector3.one * size, Vector3.zero).magnitude - round;
    }

    public static float Sphere(Vector3 pos, float radius)
    {
        return pos.magnitude - radius;
    }

    public static float Floor(Vector3 pos)
    {
        return Vector3.Dot(pos, Vector3.up) + 1f;
    }

    public static float SmoothMin(float d1, float d2, float k)
    {
        float h = Mathf.Exp(-k * d1) + Mathf.Exp(-k * d2);
        return -Mathf.Log(h) / k;
    }

    public static float CalcDistance(Vector3 pos)
    {
        float d1 = RoundBox(Repeat(pos, new Vector3(6, 6, 6)), 1, 0.2f);
        float d2 = Sphere(pos, 3f);
        float d3 = Floor(pos - new Vector3(0, -3, 0));
        return SmoothMin(SmoothMin(d1, d2, 1f), d3, 1f);
    }

    public static Vector3 CalcNormal(Vector3 pos)
    {
        var d = 0.01f;
        return new Vector3(
            CalcDistance(pos + new Vector3( d, 0f, 0f)) - CalcDistance(pos + new Vector3(-d, 0f, 0f)),
            CalcDistance(pos + new Vector3(0f,  d, 0f)) - CalcDistance(pos + new Vector3(0f, -d, 0f)),
            CalcDistance(pos + new Vector3(0f, 0f,  d)) - CalcDistance(pos + new Vector3(0f, 0f, -d))).normalized;
    }
}

public class Mover : MonoBehaviour 
{
    [SerializeField] float radius          = 0.5f;
    [SerializeField] float friction        = 0.3f;
    [SerializeField] float angularFriction = 0.6f;
    [SerializeField] float restitution     = 0.9f;

    private const float MAX_DIST = 10f;
    private const float MIN_DIST = 0.01f;

    private const float STATIC_GRAVITY_MODIFIER  = 1.2f;
    private const float BUERIED_GRAVITY_MODIFIER = 3f;

    private Rigidbody rigidbody_;

    struct RaymarchingResult
    {
        public int     loop;
        public bool    isBuried;
        public float   distance;
        public float   length;
        public Vector3 direction;
        public Vector3 position;
        public Vector3 normal;
    }

    RaymarchingResult Raymarching(Vector3 dir)
    {
        var dist = 0f;
        var len  = 0f;
        var pos  = transform.position + radius * dir;
        var loop = 0;

        for (loop = 0; loop < 10; ++loop) {
            dist = DistanceFunction.CalcDistance(pos);
            len += dist;
            pos += dir * dist;
            if (dist < MIN_DIST || len > MAX_DIST) break;
        }

        var result = new RaymarchingResult();

        result.loop      = loop;
        result.isBuried  = DistanceFunction.CalcDistance(transform.position) < MIN_DIST;
        result.distance  = dist;
        result.length    = len;
        result.direction = dir;
        result.position  = pos;
        result.normal    = DistanceFunction.CalcNormal(pos);

        return result;
    }

    void Start()
    {
        rigidbody_ = GetComponent<Rigidbody>();
    }   

    void FixedUpdate()
    {
        var ray = Raymarching(rigidbody_.velocity.normalized);
        var v = rigidbody_.velocity;
        var g = Physics.gravity;

        // 埋まっているときは脱出方向へ力をかける
        if (ray.isBuried) {
            rigidbody_.AddForce((rigidbody_.mass * g.magnitude * BUERIED_GRAVITY_MODIFIER) * ray.normal);
        // 衝突時は速度の跳ね返りの計算とめり込み対策
        } else if (ray.length < MIN_DIST) {
            var prod = Vector3.Dot(v.normalized, ray.normal);
            // 衝突面垂直方向速度
            var vv = (prod * v.magnitude) * ray.normal;
            // 衝突面水平方向速度
            var vh = v - vv;
            // 摩擦と跳ね返り係数を考慮して減速
            rigidbody_.velocity = vh * (1f - friction) + (-vv * restitution);
            // 静止時に埋まりを避けるために鉛直上向きの垂直抗力（ちょっと強めに補正）を加える
            rigidbody_.AddForce(-rigidbody_.mass * STATIC_GRAVITY_MODIFIER * g);
            // 回転の摩擦は適当に与える
            rigidbody_.AddTorque(-rigidbody_.angularVelocity * (1f - angularFriction));
        }
    }
}
