{
  titanfall2,
  northstar,
  symlinkJoin,
}:
symlinkJoin {
  name = "northstar-dedicated";
  paths = [
    titanfall2
    northstar
  ];
}
