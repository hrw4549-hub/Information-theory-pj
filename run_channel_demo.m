function run_channel_demo()
%RUN_CHANNEL_DEMO Generate reproducible BER and FER comparison figures.
    project_root = fileparts(mfilename('fullpath'));
    addpath(fullfile(project_root, 'src'));
    old_dir = pwd;
    cleanup = onCleanup(@() cd(old_dir));
    cd(fullfile(project_root, 'results'));
    main_demo();
    clear cleanup;
end
