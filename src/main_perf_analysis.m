function results = main_perf_analysis()
%MAIN_PERF_ANALYSIS Keep the original course entry point for image analysis.
    project_root = fileparts(fileparts(mfilename('fullpath')));
    addpath(project_root);
    results = run_image_demo();
end
