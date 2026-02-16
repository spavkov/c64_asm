using SDL2;

namespace DemoEffectsShowcase.Core;

public static class SdlFx
{
    public static void FillRect(IntPtr renderer, int x, int y, int w, int h, byte r, byte g, byte b, byte a = 255)
    {
        SDL.SDL_SetRenderDrawColor(renderer, r, g, b, a);
        var rect = new SDL.SDL_Rect { x = x, y = y, w = w, h = h };
        SDL.SDL_RenderFillRect(renderer, ref rect);
    }

    public static void Line(IntPtr renderer, int x1, int y1, int x2, int y2, byte r, byte g, byte b, byte a = 255)
    {
        SDL.SDL_SetRenderDrawColor(renderer, r, g, b, a);
        SDL.SDL_RenderDrawLine(renderer, x1, y1, x2, y2);
    }

    public static void FilledCircle(IntPtr renderer, int cx, int cy, int radius, byte r, byte g, byte b, byte a = 255)
    {
        SDL.SDL_SetRenderDrawColor(renderer, r, g, b, a);
        for (var y = -radius; y <= radius; y++)
        {
            var span = (int)MathF.Sqrt(radius * radius - y * y);
            SDL.SDL_RenderDrawLine(renderer, cx - span, cy + y, cx + span, cy + y);
        }
    }
}
