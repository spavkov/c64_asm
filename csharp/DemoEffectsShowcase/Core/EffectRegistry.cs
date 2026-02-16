using DemoEffectsShowcase.Effects;

namespace DemoEffectsShowcase.Core;

public static class EffectRegistry
{
    public static IReadOnlyList<EffectDescriptor> CreateDefault() =>
    [
        new()
        {
            Id = "plasma",
            Name = "Plasma",
            Description = "Classic sine plasma color field.",
            Category = "Raster",
            Tags = ["amiga", "commodore", "sine", "color"],
            Factory = static () => new PlasmaEffect()
        },
        new()
        {
            Id = "starfield",
            Name = "Starfield",
            Description = "3D starfield flying toward camera.",
            Category = "3D Illusion",
            Tags = ["space", "vector", "zoom"],
            Factory = static () => new StarfieldEffect()
        },
        new()
        {
            Id = "copper-bars",
            Name = "Copper Bars",
            Description = "Horizontal moving bars inspired by copper effects.",
            Category = "Raster",
            Tags = ["copper", "bars", "scanline"],
            Factory = static () => new CopperBarsEffect()
        },
        new()
        {
            Id = "tunnel",
            Name = "Tunnel",
            Description = "Forward-moving texture tunnel illusion.",
            Category = "3D Illusion",
            Tags = ["tunnel", "polar", "depth"],
            Factory = static () => new TunnelEffect()
        },
        new()
        {
            Id = "rotozoom",
            Name = "Rotozoom",
            Description = "Rotating and zooming tiled texture effect.",
            Category = "Transform",
            Tags = ["rotation", "zoom", "texture"],
            Factory = static () => new RotozoomEffect()
        },
        new()
        {
            Id = "fire",
            Name = "Fire",
            Description = "Palette-based procedural flame effect.",
            Category = "Simulation",
            Tags = ["fire", "palette", "flame"],
            Factory = static () => new FireEffect()
        },
        new()
        {
            Id = "sine-scroller",
            Name = "Sine Scroller",
            Description = "Horizontal text scroller on a sine wave.",
            Category = "Text",
            Tags = ["sine", "scroller", "text"],
            Factory = static () => new SineScrollerEffect()
        },
        new()
        {
            Id = "cube-twister",
            Name = "Cube Twister",
            Description = "Amiga-style twisting ribbon/cube bars.",
            Category = "3D Illusion",
            Tags = ["twister", "cube", "ribbon"],
            Factory = static () => new CubeTwisterEffect()
        },
        new()
        {
            Id = "wireframe-cube",
            Name = "Wireframe Cube",
            Description = "Classic rotating 3D wireframe cube.",
            Category = "3D",
            Tags = ["wireframe", "cube", "vector"],
            Factory = static () => new WireframeCubeEffect()
        },
        new()
        {
            Id = "glenz-cube",
            Name = "Glenz Vectors Cube",
            Description = "Transparent glenz-style cube faces.",
            Category = "3D",
            Tags = ["glenz", "cube", "transparent"],
            Factory = static () => new GlenzVectorsCubeEffect()
        },
        new()
        {
            Id = "textured-cube",
            Name = "Textured Cube",
            Description = "Rotating cube textured on all faces.",
            Category = "3D",
            Tags = ["cube", "texture", "mapped"],
            Factory = static () => new TexturedCubeEffect()
        },
        new()
        {
            Id = "cube-plasma-side",
            Name = "Cube + Plasma Side",
            Description = "Rotating cube with one plasma face.",
            Category = "3D",
            Tags = ["cube", "plasma", "hybrid"],
            Factory = static () => new CubePlasmaSideEffect()
        },
        new()
        {
            Id = "meatballs",
            Name = "Meatballs",
            Description = "Metaballs scalar-field effect.",
            Category = "Simulation",
            Tags = ["metaballs", "blob", "field"],
            Factory = static () => new MeatballsEffect()
        },
        new()
        {
            Id = "vectorballs",
            Name = "Vectorballs",
            Description = "3D rotating vector ball cloud.",
            Category = "3D",
            Tags = ["vectorballs", "balls", "3d"],
            Factory = static () => new VectorBallsEffect()
        }
    ];
}
