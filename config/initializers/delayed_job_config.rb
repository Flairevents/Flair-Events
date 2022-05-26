# Keep failed jobs around for inspection
Delayed::Worker.destroy_failed_jobs = false

# Make max_run_time a bit longer to be safe
Delayed::Worker.max_run_time = 12.hours
