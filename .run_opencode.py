import subprocess, sys, pathlib

task_file = pathlib.Path("/home/house/watch/.opencode-task-md-clean.txt")
task = pathlib.Path("/home/house/watch/.opencode-task.md").read_text()
task_file.write_text(task)

result = subprocess.run(
    [
        "opencode", "run",
        "--model", "openrouter/deepseek/deepseek-chat-v4-flash",
        "--title", "watch-build",
        task
    ],
    capture_output=True, text=True,
    cwd="/home/house/watch",
    timeout=550,
)
print("STDOUT:", result.stdout[:5000])
print("STDERR:", result.stderr[:3000])
print("RC:", result.returncode)
sys.exit(result.returncode)
