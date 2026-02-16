using DemoEffectsShowcase.Core;
using SDL2;

namespace DemoEffectsShowcase.App;

public sealed class DemoShowcaseApp
{
    private const int WindowWidth = 1280;
    private const int WindowHeight = 820;
    private const int LeftWidth = 360;
    private const int SearchHeight = 34;
    private const int ListHeight = 320;
    private const int RowHeight = 22;

    private readonly List<EffectDescriptor> _all = [];
    private readonly List<EffectDescriptor> _filtered = [];
    private DemoSceneEffect? _active;
    private int _selectedIndex;
    private string _search = string.Empty;
    private IntPtr _window;
    private IntPtr _renderer;
    private bool _running;
    private bool _draggingSlider;
    private int _dragParamIndex = -1;
    private int _dragColorChannel = -1;

    public void Run()
    {
        SDL.SDL_Init(SDL.SDL_INIT_VIDEO);
        _window = SDL.SDL_CreateWindow("Demo Effects Showcase", SDL.SDL_WINDOWPOS_CENTERED, SDL.SDL_WINDOWPOS_CENTERED, WindowWidth, WindowHeight, SDL.SDL_WindowFlags.SDL_WINDOW_RESIZABLE);
        _renderer = SDL.SDL_CreateRenderer(_window, -1, SDL.SDL_RendererFlags.SDL_RENDERER_ACCELERATED | SDL.SDL_RendererFlags.SDL_RENDERER_PRESENTVSYNC);

        _all.AddRange(EffectRegistry.CreateDefault());
        ApplyFilter();
        ActivateSelected();
        _running = true;

        var freq = SDL.SDL_GetPerformanceFrequency();
        var prev = SDL.SDL_GetPerformanceCounter();
        while (_running)
        {
            var now = SDL.SDL_GetPerformanceCounter();
            var dt = (now - prev) / (double)freq;
            prev = now;
            HandleEvents();
            RenderFrame(dt);
        }

        _active?.Dispose();
        SDL.SDL_DestroyRenderer(_renderer);
        SDL.SDL_DestroyWindow(_window);
        SDL.SDL_Quit();
    }

    private void HandleEvents()
    {
        while (SDL.SDL_PollEvent(out var ev) == 1)
        {
            if (ev.type == SDL.SDL_EventType.SDL_QUIT) { _running = false; return; }
            if (ev.type == SDL.SDL_EventType.SDL_MOUSEBUTTONDOWN) HandleMouseDown(ev.button.x, ev.button.y);
            if (ev.type == SDL.SDL_EventType.SDL_MOUSEBUTTONUP) { _draggingSlider = false; _dragParamIndex = -1; _dragColorChannel = -1; }
            if (ev.type == SDL.SDL_EventType.SDL_MOUSEMOTION && _draggingSlider) HandleMouseDrag(ev.motion.x);
            if (ev.type == SDL.SDL_EventType.SDL_KEYDOWN) HandleKey(ev.key.keysym.sym);
        }
    }

    private void HandleKey(SDL.SDL_Keycode key)
    {
        if (key == SDL.SDL_Keycode.SDLK_ESCAPE) { _running = false; return; }
        if (key == SDL.SDL_Keycode.SDLK_BACKSPACE && _search.Length > 0) { _search = _search[..^1]; ApplyFilter(); ActivateSelected(); return; }
        if (key is >= SDL.SDL_Keycode.SDLK_a and <= SDL.SDL_Keycode.SDLK_z) { _search += (char)('a' + (key - SDL.SDL_Keycode.SDLK_a)); ApplyFilter(); ActivateSelected(); return; }
        if (key == SDL.SDL_Keycode.SDLK_SPACE) { _search += ' '; ApplyFilter(); ActivateSelected(); return; }
        if (key == SDL.SDL_Keycode.SDLK_UP && _selectedIndex > 0) { _selectedIndex--; ActivateSelected(); return; }
        if (key == SDL.SDL_Keycode.SDLK_DOWN && _selectedIndex < _filtered.Count - 1) { _selectedIndex++; ActivateSelected(); return; }
    }

    private void HandleMouseDown(int x, int y)
    {
        if (x > LeftWidth) return;
        if (y >= SearchHeight + 8 && y < SearchHeight + 8 + ListHeight)
        {
            var idx = (y - (SearchHeight + 8)) / RowHeight;
            if (idx >= 0 && idx < _filtered.Count) { _selectedIndex = idx; ActivateSelected(); }
            return;
        }

        var parameters = _active?.GetParameters() ?? [];
        var baseY = SearchHeight + 8 + ListHeight + 16;
        for (var i = 0; i < parameters.Count; i++)
        {
            var p = parameters[i];
            var py = baseY + i * 42;
            if (p.Kind == EffectParameterKind.Float)
            {
                if (y >= py + 16 && y <= py + 30) { _draggingSlider = true; _dragParamIndex = i; _dragColorChannel = -1; HandleMouseDrag(x); return; }
            }
            else
            {
                for (var c = 0; c < 3; c++)
                {
                    var sy = py + 10 + c * 9;
                    if (y >= sy && y <= sy + 7) { _draggingSlider = true; _dragParamIndex = i; _dragColorChannel = c; HandleMouseDrag(x); return; }
                }
            }
        }
    }

    private void HandleMouseDrag(int x)
    {
        if (_active is null || _dragParamIndex < 0) return;
        var p = _active.GetParameters()[_dragParamIndex];
        var t = Math.Clamp((x - 16f) / (LeftWidth - 32f), 0f, 1f);
        if (_dragColorChannel < 0 && p.Kind == EffectParameterKind.Float)
        {
            p.SetFloat(p.Min + t * (p.Max - p.Min));
            return;
        }
        if (_dragColorChannel >= 0 && p.Kind == EffectParameterKind.Color3)
        {
            var c = p.GetColor3();
            if (_dragColorChannel == 0) c.X = t; else if (_dragColorChannel == 1) c.Y = t; else c.Z = t;
            p.SetColor3(c);
        }
    }

    private void RenderFrame(double dt)
    {
        SDL.SDL_SetRenderDrawColor(_renderer, 10, 12, 16, 255);
        SDL.SDL_RenderClear(_renderer);

        SDL.SDL_GetWindowSize(_window, out var w, out var h);
        DrawLeftPanel(h);
        DrawRightPanel(w, h, dt);
        SDL.SDL_RenderPresent(_renderer);
        UpdateTitle();
    }

    private void DrawLeftPanel(int h)
    {
        var panel = new SDL.SDL_Rect { x = 0, y = 0, w = LeftWidth, h = h };
        SDL.SDL_SetRenderDrawColor(_renderer, 28, 32, 40, 255);
        SDL.SDL_RenderFillRect(_renderer, ref panel);

        var search = new SDL.SDL_Rect { x = 10, y = 8, w = LeftWidth - 20, h = SearchHeight };
        SDL.SDL_SetRenderDrawColor(_renderer, 45, 50, 62, 255);
        SDL.SDL_RenderFillRect(_renderer, ref search);
        SdlText.Draw(_renderer, "EFFECTS", 12, 10, 1, 235, 245, 255);
        SdlText.Draw(_renderer, $"SEARCH: {_search}", 14, 18, 1, 190, 205, 220);

        var listTop = SearchHeight + 8;
        for (var i = 0; i < _filtered.Count && i < ListHeight / RowHeight; i++)
        {
            var row = new SDL.SDL_Rect { x = 10, y = listTop + i * RowHeight, w = LeftWidth - 20, h = RowHeight - 2 };
            var selected = i == _selectedIndex;
            SDL.SDL_SetRenderDrawColor(_renderer, selected ? (byte)88 : (byte)56, selected ? (byte)122 : (byte)60, selected ? (byte)164 : (byte)72, 255);
            SDL.SDL_RenderFillRect(_renderer, ref row);
            SdlText.Draw(_renderer, _filtered[i].Name, 16, listTop + i * RowHeight + 6, 1, 240, 245, 255);
        }

        var parameters = _active?.GetParameters() ?? [];
        var baseY = SearchHeight + 8 + ListHeight + 16;
        SdlText.Draw(_renderer, "EFFECT CONTROLS", 12, baseY - 12, 1, 220, 230, 245);
        for (var i = 0; i < parameters.Count; i++)
        {
            var p = parameters[i];
            var y = baseY + i * 42;
            SdlText.Draw(_renderer, p.Label, 16, y + 2, 1, 210, 220, 235);
            if (p.Kind == EffectParameterKind.Float)
            {
                DrawSlider(y + 16, p.GetFloat(), p.Min, p.Max, 84, 130, 196);
            }
            else
            {
                var c = p.GetColor3();
                DrawSlider(y + 10, c.X, 0, 1, 220, 70, 70);
                DrawSlider(y + 19, c.Y, 0, 1, 70, 220, 70);
                DrawSlider(y + 28, c.Z, 0, 1, 70, 120, 220);
            }
        }
    }

    private void DrawSlider(int y, float v, float min, float max, byte r, byte g, byte b)
    {
        var bg = new SDL.SDL_Rect { x = 16, y = y, w = LeftWidth - 32, h = 8 };
        SDL.SDL_SetRenderDrawColor(_renderer, 52, 56, 66, 255);
        SDL.SDL_RenderFillRect(_renderer, ref bg);
        var t = (v - min) / (max - min);
        var fg = new SDL.SDL_Rect { x = 16, y = y, w = Math.Max(1, (int)((LeftWidth - 32) * Math.Clamp(t, 0f, 1f))), h = 8 };
        SDL.SDL_SetRenderDrawColor(_renderer, r, g, b, 255);
        SDL.SDL_RenderFillRect(_renderer, ref fg);
    }

    private void DrawRightPanel(int w, int h, double dt)
    {
        var right = new SDL.SDL_Rect { x = LeftWidth, y = 0, w = Math.Max(1, w - LeftWidth), h = h };
        SDL.SDL_SetRenderDrawColor(_renderer, 8, 10, 14, 255);
        SDL.SDL_RenderFillRect(_renderer, ref right);
        if (_active is null) return;

        SDL.SDL_RenderSetViewport(_renderer, ref right);
        _active.Resize(right.w, right.h);
        _active.Update(dt);
        _active.Render(_renderer);
        var full = new SDL.SDL_Rect { x = 0, y = 0, w = w, h = h };
        SDL.SDL_RenderSetViewport(_renderer, ref full);
    }

    private void ApplyFilter()
    {
        _filtered.Clear();
        foreach (var e in _all)
        {
            if (string.IsNullOrWhiteSpace(_search) || e.Name.Contains(_search, StringComparison.OrdinalIgnoreCase) || e.Tags.Any(t => t.Contains(_search, StringComparison.OrdinalIgnoreCase)))
            {
                _filtered.Add(e);
            }
        }
        if (_filtered.Count == 0) { _selectedIndex = 0; _active?.Dispose(); _active = null; }
        else _selectedIndex = Math.Clamp(_selectedIndex, 0, _filtered.Count - 1);
    }

    private void ActivateSelected()
    {
        if (_filtered.Count == 0) return;
        var d = _filtered[_selectedIndex];
        if (_active?.Id == d.Id) return;
        _active?.Dispose();
        _active = d.Factory();
        _active.Initialize(new EffectInitContext(1, 1));
    }

    private void UpdateTitle()
    {
        var name = _active?.Name ?? "No effect";
        SDL.SDL_SetWindowTitle(_window, $"Demo Effects Showcase | {name} | Search: {_search}");
    }
}
