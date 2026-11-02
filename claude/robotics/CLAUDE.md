# Project guidelines (ROS 2)

## Working principles
- Make the smallest change that solves the task. Do not refactor, rename, reformat or "improve" code you were not asked to touch.
- Match the existing style of the file and package: naming, structure, includes/imports, error handling, logging, formatting. When in doubt, imitate the nearest similar code.
- Do not add features, parameters, abstractions or fallbacks that were not requested.
- Do not add dependencies (package.xml, CMakeLists.txt, setup.py, requirements) without asking.
- If the request is ambiguous or touches more than expected, ask before proceeding.

## Comments
- Write as few comments as possible. Code must be self-explanatory through clear names and small functions.
- Only comment non-obvious *why* (hardware quirk, protocol constraint, workaround). Never describe *what* the code does.
- No commented-out code, no TODOs, no changelog-style comments, no section banners.
- Do not add or rewrite docstrings on code you did not change.

## Code quality
- Keep functions short and single-purpose. Prefer early returns over deep nesting.
- No magic numbers: use ROS parameters or named constants.
- Handle errors the way the surrounding code does; do not swallow exceptions silently.
- Remove any unused code, imports and variables your change leaves behind.

## ROS 2 conventions
- Follow REP-103 (SI units, right-handed frames) and REP-105 (frame naming: map, odom, base_link).
- Never hardcode topic, service, action or frame names inside logic: use parameters or remappable names, and relative names unless a global one is required.
- Declare every parameter with a default and, where useful, a descriptor. Read parameters once, react to changes via the parameter callback.
- Pick QoS deliberately: sensor data uses `SensorDataQoS`, latched/config data uses transient local, commands use reliable. Match the QoS already used on that topic.
- Use `RCLCPP_*` / `get_logger()` for logging, never `print` / `std::cout`. Use `_THROTTLE` variants for high-rate loops.
- Do not block in callbacks. Use timers, separate callback groups or executors for long work. Never call `spin_until_future_complete` inside a callback.
- Use `this->now()` / the node clock, never wall time, so `use_sim_time` keeps working.
- Prefer composition and lifecycle nodes where the package already uses them.
- Keep message/service/action definitions backward compatible unless asked.
- Launch files: expose arguments with `DeclareLaunchArgument`, keep the same format (Python/XML/YAML) the package already uses.

## Build and test
- Build only what changed: `colcon build --packages-select <pkg>` (add `--symlink-install` if the workspace uses it). Never build the whole workspace unless asked.
- Source the overlay (`source install/setup.bash`) before running tests or nodes.
- Test with `colcon test --packages-select <pkg>` then `colcon test-result --verbose`.
- Run the linters the package already uses (ament_lint, clang-format, ruff/flake8, black) and fix only the issues your change introduced.
- Never edit or read `build/`, `install/` or `log/`.

## Safety (real robots)
- Never run commands that publish to actuator, motion or cmd_vel topics, call motion services/actions, flash firmware, or change hardware state unless explicitly asked.
- Treat parameter limits (velocity, acceleration, torque, joint limits) as safety-critical: never loosen them without being asked.
- Prefer simulation or `ros2 bag` playback for verification.

## Git
- Do not commit, push, or create branches unless asked.
- Follow the repository's existing commit message convention.
