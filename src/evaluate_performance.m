function [mse_val, psnr_val, ber_img] = evaluate_performance(img_org, img_rec)
    I1 = double(img_org);
    I2 = double(img_rec);
    [M, N] = size(I1);
    
    % 计算 MSE
    mse_val = sum((I1(:) - I2(:)).^2) / (M * N);
    
    % 计算 PSNR
    if mse_val == 0
        psnr_val = Inf;
    else
        psnr_val = 10 * log10((255^2) / mse_val);
    end
    
    % 纯数学逻辑替代 int2bit：先用 double() 转换为双精度，再进行矩阵位运算
    bit_org = rem(floor(double(img_org(:)) * 2.^(-7:0)), 2) > 0;
    bit_rec = rem(floor(double(img_rec(:)) * 2.^(-7:0)), 2) > 0;
    
    % 计算位误码率
    ber_img = sum(bit_org(:) ~= bit_rec(:)) / numel(bit_org);
end