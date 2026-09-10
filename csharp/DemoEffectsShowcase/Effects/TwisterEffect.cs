using DemoEffectsShowcase.Core;
using SDL2;
using System.Runtime.InteropServices;

namespace DemoEffectsShowcase.Effects;

/// <summary>
/// Classic C64-style chrome twister: a column of stacked horizontal slices whose
/// four phase-shifted edges form a twisting metallic ribbon. The twist speed
/// follows a forward-only sine-wave rhythm while gentle traveling waves keep the column
/// moving without changing its overall shape abruptly.
/// </summary>
public sealed class TwisterEffect : DemoSceneEffect
{
    // Fixed internal render resolution (4:3); scaled to fill the panel.
    private const int IW = 384;
    private const int IH = 288;

    private const float P2 = 1.57079632679f;  // pi/2

    private const float TwistFreq = 7.0f;
    private const float FlowFactor = 0.72f;

    // ---- Forward rotation controls (exposed as sliders) ----
    private float _standstillDur = 0.5f;
    private float _cycleDur = 10.5f;
    private float _turnsPerCycle = 1.35f;
    private float _pulseStrength = 1f;

    // Animation state.
    private double _time;
    private float _spinPhase;
    private float _flowPhase;

    private readonly uint[] _pixels = new uint[IW * IH];
    private IntPtr _texture = IntPtr.Zero;
    private int _panelW = 1;
    private int _panelH = 1;

    private readonly IReadOnlyList<EffectParameterDefinition> _parameters;

    public TwisterEffect()
    {
        _parameters =
        [
            EffectParameters.Float("standstill", "Standstill (s)", () => _standstillDur, v => _standstillDur = v, 0f, 10f),
            EffectParameters.Float("cycle", "Cycle Duration (s)", () => _cycleDur, v => _cycleDur = v, 2f, 20f),
            EffectParameters.Float("turns", "Turns / Cycle", () => _turnsPerCycle, v => _turnsPerCycle = v, 0.5f, 3f),
            EffectParameters.Float("pulse", "Pulse Strength", () => _pulseStrength, v => _pulseStrength = v, 0f, 1f)
        ];
    }

    public string Id => "twister";
    public string Name => "Twister";
    public string Description => "C64-style chrome twister with smooth, forward-only sine-wave rotation.";
    public IReadOnlyList<string> Tags => ["twister", "chrome", "c64", "scanline", "ribbon"];

    public void Initialize(in EffectInitContext context)
    {
        _panelW = Math.Max(1, context.Width);
        _panelH = Math.Max(1, context.Height);
    }

    public void Resize(int width, int height)
    {
        _panelW = Math.Max(1, width);
        _panelH = Math.Max(1, height);
    }

    public void Update(double deltaSeconds)
    {
        // A debugger pause or dragged window must not turn into a visible phase jump.
        var dt = Math.Clamp((float)deltaSeconds, 0f, 1f / 30f);
        var previousTime = _time;
        _time += dt;

        // Integrate only this frame so changing controls cannot rewind the rotation.
        _spinPhase += (float)Math.Max(0, ForwardSpin(_time) - ForwardSpin(previousTime));
        _flowPhase = _spinPhase * FlowFactor;
    }

    public void Render(IntPtr renderer)
    {
        if (_texture == IntPtr.Zero)
        {
            _texture = SDL.SDL_CreateTexture(renderer, SDL.SDL_PIXELFORMAT_ARGB8888,
                (int)SDL.SDL_TextureAccess.SDL_TEXTUREACCESS_STREAMING, IW, IH);
        }

        FillPixels();

        var handle = GCHandle.Alloc(_pixels, GCHandleType.Pinned);
        try
        {
            SDL.SDL_UpdateTexture(_texture, IntPtr.Zero, handle.AddrOfPinnedObject(), IW * sizeof(uint));
        }
        finally
        {
            handle.Free();
        }

        // White background fills the whole panel so the scaled column blends seamlessly.
        SdlFx.FillRect(renderer, 0, 0, _panelW, _panelH, 255, 255, 255);

        // Scale to fit the panel while preserving the 4:3 aspect, centered.
        var scale = MathF.Min(_panelW / (float)IW, _panelH / (float)IH);
        var dw = Math.Max(1, (int)(IW * scale));
        var dh = Math.Max(1, (int)(IH * scale));
        var dst = new SDL.SDL_Rect { x = (_panelW - dw) / 2, y = (_panelH - dh) / 2, w = dw, h = dh };
        SDL.SDL_RenderCopy(renderer, _texture, IntPtr.Zero, ref dst);
    }

    public void Dispose()
    {
        if (_texture != IntPtr.Zero)
        {
            SDL.SDL_DestroyTexture(_texture);
            _texture = IntPtr.Zero;
        }
    }

    public IReadOnlyList<EffectParameterDefinition> GetParameters() => _parameters;

    private double ForwardSpin(double t)
    {
        if (t <= _standstillDur) return 0f;

        var elapsed = t - _standstillDur;
        var cycles = elapsed / _cycleDur;
        var progress = cycles - Math.Floor(cycles);
        // Integral of speed = averageSpeed * (1 - pulse * cos(phase)).
        // A pulse in [0, 1] eases the speed without ever making it negative.
        return _turnsPerCycle * Math.Tau *
            (cycles - _pulseStrength * Math.Sin(progress * Math.Tau) / Math.Tau);
    }

    private void FillPixels()
    {
        var spin = _spinPhase;
        var flow = _flowPhase;

        Span<float> v = stackalloc float[4];
        Span<float> phi = stackalloc float[4];

        for (var y = 0; y < IH; y++)
        {
            var uy = y / (float)IH * 2f - 1f;

            var sway = 0.07f * MathF.Sin(flow * 0.55f - uy * 2.3f)
                     + 0.025f * MathF.Sin(flow * 0.27f + uy * 5.1f);
            var ampX = 0.52f + 0.045f * MathF.Sin(flow * 0.4f - uy * 1.8f);
            var a = spin + uy * TwistFreq
                  + 0.55f * MathF.Sin(uy * 2.2f - flow)
                  + 0.12f * MathF.Sin(uy * 5.4f + flow * 0.55f);

            for (var i = 0; i < 4; i++)
            {
                phi[i] = a + P2 * i;
                v[i] = ampX * MathF.Sin(phi[i]) + sway;
            }

            var rowOff = y * IW;
            for (var x = 0; x < IW; x++)
            {
                var ux = x / (float)IW * 2f - 1f;
                var gray = 1.0f; // white background

                for (var i = 0; i < 4; i++)
                {
                    var p = v[i];
                    var n = v[(i + 1) & 3];
                    var k = n - p;
                    if (k > 0f && ux > p && ux < n)
                    {
                        var xf = (ux - p) / k;

                        // Surface angle sweeps across the visible face -> chrome gradient.
                        var ang = phi[i] + xf * P2;
                        var diffuse = 0.5f + 0.5f * MathF.Cos(ang);
                        var spec = MathF.Pow(MathF.Max(0f, MathF.Cos(ang)), 22f);

                        var facing = k / (2f * ampX); // grazing faces darker
                        var g = diffuse * (0.45f + 0.55f * facing) + spec * 0.9f;

                        // Dark creases where faces meet (the black diamond notches).
                        var crease = Smoothstep01(xf, 0.10f) * Smoothstep01(1f - xf, 0.10f);
                        g *= 0.15f + 0.85f * crease;

                        gray = Math.Clamp(g, 0f, 1f);
                    }
                }

                var c = (byte)(gray * 255f);
                _pixels[rowOff + x] = 0xFF000000u | ((uint)c << 16) | ((uint)c << 8) | c;
            }
        }
    }

    private static float Smoothstep01(float x, float edge)
    {
        var t = Math.Clamp(x / edge, 0f, 1f);
        return t * t * (3f - 2f * t);
    }
}
