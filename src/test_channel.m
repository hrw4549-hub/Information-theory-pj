function results = test_channel()
%TEST_CHANNEL Check BPSK/AWGN BER against the analytical reference curve.
    rng(20261109);
    n_bits = 1e6;
    ebn0_values = 0:2:8;
    bits = logical(randi([0 1], 1, n_bits));
    simulated = zeros(size(ebn0_values));
    theoretical = 0.5 * erfc(sqrt(10.^(ebn0_values / 10)));

    for k = 1:numel(ebn0_values)
        [llr, ~] = awgn_llr(bits, ebn0_values(k), 1);
        received = llr < 0;
        simulated(k) = mean(received ~= bits);
    end

    % A six-sigma band accounts for finite Monte Carlo sampling.
    sigma = sqrt(theoretical .* (1 - theoretical) / n_bits);
    pass_points = abs(simulated - theoretical) <= 6 * sigma + 1 / n_bits;
    results.total = numel(ebn0_values);
    results.pass = sum(pass_points);
    results.fail = results.total - results.pass;
    results.simulated_ber = simulated;
    results.theoretical_ber = theoretical;
    results.ebn0_dB = ebn0_values;

    figure('Color', 'w');
    semilogy(ebn0_values, simulated, 'o-', 'LineWidth', 1.5); hold on;
    semilogy(ebn0_values, theoretical, '--', 'LineWidth', 1.5);
    grid on; xlabel('Eb/N0 (dB)'); ylabel('BER');
    title('BPSK over AWGN: simulation and theory');
    legend('Simulation', 'Theory', 'Location', 'southwest');
    project_root = fileparts(fileparts(mfilename('fullpath')));
    results_dir = fullfile(project_root, 'results');
    if ~exist(results_dir, 'dir'), mkdir(results_dir); end
    exportgraphics(gcf, fullfile(results_dir, 'bpsk-awgn-ber.png'), 'Resolution', 160);
    close(gcf);

    for k = 1:numel(ebn0_values)
        fprintf('Eb/N0=%2d dB | simulated %.6g | theory %.6g | %s\n', ...
            ebn0_values(k), simulated(k), theoretical(k), state(pass_points(k)));
    end
end

function label = state(passed)
    if passed, label = 'PASS'; else, label = 'FAIL'; end
end
