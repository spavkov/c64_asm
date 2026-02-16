using DemoEffectsShowcase.App;

var startupEffectId = args.Length > 0 ? args[0] : null;
new DemoShowcaseApp(startupEffectId).Run();
