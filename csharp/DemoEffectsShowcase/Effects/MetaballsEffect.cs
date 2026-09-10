using DemoEffectsShowcase.Core;
using SDL2;
using System.Numerics;
using System.Runtime.InteropServices;

namespace DemoEffectsShowcase.Effects;

public sealed class MetaballsEffect : DemoSceneEffect
{
    private const int Width = 320;
    private const int Height = 240;
    private const int MaxBalls = 12;
    private static readonly Vector3 Background = new(0.025f, 0.035f, 0.065f);
    private static readonly Vector3 Light = Vector3.Normalize(new Vector3(-0.5f, -0.6f, 1f));
    private static readonly Vector3 Halfway = Vector3.Normalize(Light + Vector3.UnitZ);

    private readonly uint[] _pixels = new uint[Width * Height];
    private readonly IReadOnlyList<EffectParameterDefinition> _parameters;
    private IntPtr _texture;
    private int _panelW = 1;
    private int _panelH = 1;
    private double _time;
    private int _ballCount = 5;
    private float _speed = 0.7f;
    private float _radius = 24f;
    private float _threshold = 1f;
    private float _shine = 0.75f;
    private Vector3 _color = new(0.12f, 0.65f, 0.95f);

    public MetaballsEffect()
    {
        _parameters =
        [
            EffectParameters.Dropdown("count", "Number of Balls",
                Enumerable.Range(1, MaxBalls).Select(n => n.ToString()).ToArray(),
                () => _ballCount - 1, v => _ballCount = Math.Clamp(v + 1, 1, MaxBalls)),
            EffectParameters.Float("speed", "Speed", () => _speed, v => _speed = v, 0f, 2f),
            EffectParameters.Float("radius", "Ball Size", () => _radius, v => _radius = v, 10f, 40f),
            EffectParameters.Float("threshold", "Merge Threshold", () => _threshold, v => _threshold = v, 0.6f, 2f),
            EffectParameters.Float("shine", "Shine", () => _shine, v => _shine = v, 0f, 1.5f),
            EffectParameters.Color3("color", "Blob Color", () => _color, v => _color = v)
        ];
    }

    public string Id => "metaballs";
    public string Name => "Metaballs";
    public string Description => "Glossy 2D blobs that smoothly merge and separate.";
    public IReadOnlyList<string> Tags => ["metaballs", "meta balls", "blob", "field", "liquid"];
    public IReadOnlyList<EffectParameterDefinition> GetParameters() => _parameters;

    public void Initialize(in EffectInitContext context)
    {
        Resize(context.Width, context.Height);
        _time = 0;
    }

    public void Resize(int width, int height)
    {
        _panelW = Math.Max(1, width);
        _panelH = Math.Max(1, height);
    }

    public void Update(double deltaSeconds) => _time += deltaSeconds * _speed;

    public void Render(IntPtr renderer)
    {
        if (_texture == IntPtr.Zero)
        {
            var previousQuality = SDL.SDL_GetHint(SDL.SDL_HINT_RENDER_SCALE_QUALITY);
            SDL.SDL_SetHint(SDL.SDL_HINT_RENDER_SCALE_QUALITY, "1");
            _texture = SDL.SDL_CreateTexture(renderer, SDL.SDL_PIXELFORMAT_ARGB8888,
                (int)SDL.SDL_TextureAccess.SDL_TEXTUREACCESS_STREAMING, Width, Height);
            SDL.SDL_SetHint(SDL.SDL_HINT_RENDER_SCALE_QUALITY, previousQuality ?? "0");
            if (_texture == IntPtr.Zero)
                throw new InvalidOperationException(SDL.SDL_GetError());
        }

        FillPixels();
        var handle = GCHandle.Alloc(_pixels, GCHandleType.Pinned);
        try
        {
            if (SDL.SDL_UpdateTexture(_texture, IntPtr.Zero, handle.AddrOfPinnedObject(), Width * sizeof(uint)) != 0)
                throw new InvalidOperationException(SDL.SDL_GetError());
        }
        finally
        {
            handle.Free();
        }

        SdlFx.FillRect(renderer, 0, 0, _panelW, _panelH, 6, 8, 16);
        var scale = MathF.Min(_panelW / (float)Width, _panelH / (float)Height);
        var w = Math.Max(1, (int)(Width * scale));
        var h = Math.Max(1, (int)(Height * scale));
        var dst = new SDL.SDL_Rect { x = (_panelW - w) / 2, y = (_panelH - h) / 2, w = w, h = h };
        SDL.SDL_RenderCopy(renderer, _texture, IntPtr.Zero, ref dst);
    }

    private void FillPixels()
    {
        Span<Vector3> balls = stackalloc Vector3[MaxBalls];
        var time = (float)_time;
        for (var i = 0; i < _ballCount; i++)
        {
            var phase = i * 2.399963f;
            var radius = _radius * (0.85f + 0.15f * MathF.Sin(i * 1.7f));
            balls[i] = new Vector3(
                Width * 0.5f + 95f * MathF.Sin(time * (0.61f + i * 0.037f) + phase),
                Height * 0.5f + 65f * MathF.Cos(time * (0.79f + i * 0.029f) + phase * 1.3f),
                radius * radius);
        }

        for (var y = 0; y < Height; y++)
        for (var x = 0; x < Width; x++)
        {
            float field = 0, gx = 0, gy = 0;
            for (var i = 0; i < _ballCount; i++)
            {
                var ball = balls[i];
                var dx = x + 0.5f - ball.X;
                var dy = y + 0.5f - ball.Y;
                var inverseDistance = 1f / (dx * dx + dy * dy + 1f);
                var contribution = ball.Z * inverseDistance;
                field += contribution;
                var slope = 2f * contribution * inverseDistance;
                gx += dx * slope;
                gy += dy * slope;
            }

            // The field gradient gives a one-pixel soft edge and an outward lighting direction.
            var gradient = MathF.Sqrt(gx * gx + gy * gy);
            var edge = MathF.Max(0.015f, gradient * 0.75f);
            var coverage = Math.Clamp((field - _threshold) / edge + 0.5f, 0f, 1f);
            coverage = coverage * coverage * (3f - 2f * coverage);
            var color = Background;
            if (coverage > 0f)
            {
                // Approximate a rounded surface from field depth; no mesh or ray marching.
                var radial = MathF.Min(1f, _threshold / field);
                var normal = new Vector3(
                    gx / MathF.Max(gradient, 0.00001f) * MathF.Sqrt(radial),
                    gy / MathF.Max(gradient, 0.00001f) * MathF.Sqrt(radial),
                    MathF.Sqrt(1f - radial));
                var diffuse = 0.25f + 0.75f * MathF.Max(0f, Vector3.Dot(normal, Light));
                var specular = _shine * MathF.Pow(MathF.Max(0f, Vector3.Dot(normal, Halfway)), 32f);
                var lit = _color * diffuse + new Vector3(specular);
                color = Vector3.Lerp(Background, lit, coverage);
            }

            color = Vector3.Clamp(color, Vector3.Zero, Vector3.One);
            _pixels[y * Width + x] = 0xFF000000u | ((uint)(color.X * 255f) << 16)
                | ((uint)(color.Y * 255f) << 8) | (uint)(color.Z * 255f);
        }
    }

    public void Dispose()
    {
        if (_texture == IntPtr.Zero) return;
        SDL.SDL_DestroyTexture(_texture);
        _texture = IntPtr.Zero;
    }
}
