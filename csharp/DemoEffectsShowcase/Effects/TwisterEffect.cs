using DemoEffectsShowcase.Core;
using SDL2;
using System.Runtime.InteropServices;

namespace DemoEffectsShowcase.Effects;

/// <summary>
/// Classic C64-style chrome twister: a column of stacked horizontal slices whose
/// four phase-shifted edges form a twisting metallic ribbon. The twist speed
/// follows a controllable rhythm (stand still -> ramp up -> ramp down -> loop),
/// with beat-snap breathing and a serpentine side-to-side sway.
/// </summary>
public sealed class TwisterEffect : DemoSceneEffect
{
    // Fixed internal render resolution (4:3); scaled to fill the panel.
    private const int IW = 384;
    private const int IH = 288;

    private const float P2 = 1.57079632679f;  // pi/2
    private const float TAU = 6.28318530718f;

    // Static feel of the column.
    private const float TwistFreq = 2.6f;   // base spatial frequency of the spiral
    private const float BeatLen = 1.36f;    // beat-snap period (in "twisting seconds")
    private const float BarLen = 2.6f;      // loose<->tight breathing period
    private const float ScrollFactor = 1.2f;// vertical band travel relative to spin

    // ---- Twist-speed rhythm controls (exposed as sliders) ----
    private float _standstillDur = 3.0f;  // initial dead-still pause (no twisting)
    private float _rampUpDur = 7.0f;      // gradually speed up (Min -> Max)
    private float _rampDownDur = 7.0f;    // gradually slow down (Max -> Min)
    private float _minSpeed = 0.20f;      // lazy speed; never fully stops after the start
    private float _maxSpeed = 3.0f;       // fast peak speed

    // Animation state.
    private float _time;
    private float _spinPhase;
    private float _scrollPhase;
    private float _beatClock;   // these advance only while twisting -> freeze when still
    private float _barClock;
    private float _swayClock;
    private float _twistAmp;
    private float _ampX;
    private float _swayAmp;

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
            EffectParameters.Float("rampup", "Ramp Up (s)", () => _rampUpDur, v => _rampUpDur = v, 0.5f, 20f),
            EffectParameters.Float("rampdown", "Ramp Down (s)", () => _rampDownDur, v => _rampDownDur = v, 0.5f, 20f),
            EffectParameters.Float("minspeed", "Min Speed", () => _minSpeed, v => _minSpeed = v, 0f, 2f),
            EffectParameters.Float("maxspeed", "Max Speed", () => _maxSpeed, v => _maxSpeed = v, 0.5f, 8f)
        ];
    }

    public string Id => "twister";
    public string Name => "Twister";
    public string Description => "C64-style chrome twister with a stand-still / speed-up / slow-down rhythm.";
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
        var dt = (float)deltaSeconds;
        _time += dt;

        var spinSpeed = RhythmSpeed(_time);
        var m = _maxSpeed > 0f ? spinSpeed / _maxSpeed : 0f; // 0 = still .. 1 = fast

        // Rotation + vertical travel follow the rhythm (frozen when standing still).
        _spinPhase += spinSpeed * dt;
        _scrollPhase += ScrollFactor * spinSpeed * dt;

        // Texture clocks advance only while twisting, so a standstill is truly frozen
        // and the slow/lazy phase pulses slowly too.
        _beatClock += m * dt;
        _barClock += m * dt;
        _swayClock += m * dt;

        // Per-beat snap envelope: jumps to 1 on the beat, decays fast.
        var bp = _beatClock / BeatLen;
        var kick = MathF.Exp(-6f * (bp - MathF.Floor(bp)));

        // Slow breathing between loose (0) and tight (1) over a bar.
        var slow = 0.5f - 0.5f * MathF.Cos(_barClock * (TAU / BarLen));
        slow *= slow; // bias toward loose, sharper tightening

        _twistAmp = 1.0f + 9.5f * slow + 1.6f * kick; // number of spiral bands
        _ampX = 0.60f - 0.20f * slow;                 // column fatter loose, slimmer tight
        _swayAmp = 0.24f + 0.14f * kick + 0.08f * slow;
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

    // Twist rotation speed for the current rhythm position (radians/sec).
    private float RhythmSpeed(float t)
    {
        if (t < _standstillDur) return 0f;                  // 1) stand perfectly still
        var ct = t - _standstillDur;
        var cycle = MathF.Max(0.001f, _rampUpDur + _rampDownDur);
        var cp = ct - cycle * MathF.Floor(ct / cycle);
        float f;
        if (cp < _rampUpDur)
            f = Smoothstep(cp / _rampUpDur);                     // 2) ease up 0 -> 1
        else
            f = Smoothstep(1f - (cp - _rampUpDur) / _rampDownDur); // 3) ease down 1 -> 0
        return _minSpeed + (_maxSpeed - _minSpeed) * f;
    }

    private void FillPixels()
    {
        var twistAmp = _twistAmp;
        var ampX = _ampX;
        var spin = _spinPhase;
        var scroll = _scrollPhase;

        Span<float> v = stackalloc float[4];
        Span<float> phi = stackalloc float[4];

        for (var y = 0; y < IH; y++)
        {
            var uy = y / (float)IH * 2f - 1f;

            // Per-row horizontal sway -> the column bends/slithers like a snake
            // (inspired by the Pico-8 "xm" offset).
            var sway = _swayAmp * MathF.Cos(_swayClock * 0.8f - uy * 1.7f
                       + 0.7f * MathF.Sin(_swayClock * 0.3f + uy * 0.6f));

            // Nested sine -> clustered "bulge" bands; scroll moves them vertically.
            var inner = uy * TwistFreq - scroll;
            var a = twistAmp * MathF.Sin(inner) + spin;

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

    private static float Smoothstep(float x)
    {
        x = Math.Clamp(x, 0f, 1f);
        return x * x * (3f - 2f * x);
    }

    private static float Smoothstep01(float x, float edge)
    {
        var t = Math.Clamp(x / edge, 0f, 1f);
        return t * t * (3f - 2f * t);
    }
}
