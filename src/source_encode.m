function [bit_stream, huff_dict, img_size] = source_encode(img_matrix)
    % 纯数学逻辑哈夫曼编码（脱离通信工具箱依赖）
    img_size = size(img_matrix);
    img_vector = double(img_matrix(:)); 
    
    % 统计符号与概率
    symbols = unique(img_vector);
    counts = histcounts(img_vector, [symbols; max(symbols)+1]);
    p = counts / sum(counts);
    
    % 手动构建哈夫曼树与字典
    n = length(p);
    cell_codes = cell(n, 1);
    
    if n == 1
        cell_codes{1} = 0;
    else
        % 简易二级结构体模拟哈夫曼树
        TREE = cell(n, 1);
        for k = 1:n
            TREE{k} = struct('symbols', k, 'prob', p(k));
        end
        
        % 追溯矩阵
        huff_tree_codes = cell(n, 1);
        while length(TREE) > 1
            % 按概率从小到大排序
            probs = cellfun(@(x) x.prob, TREE);
            [~, idx] = sort(probs);
            
            % 结合概率最低的两个节点
            node1 = TREE{idx(1)};
            node2 = TREE{idx(2)};
            
            % 分配比特 0 和 1
            for m = 1:length(node1.symbols)
                huff_tree_codes{node1.symbols(m)} = [0, huff_tree_codes{node1.symbols(m)}];
            end
            for m = 1:length(node2.symbols)
                huff_tree_codes{node2.symbols(m)} = [1, huff_tree_codes{node2.symbols(m)}];
            end
            
            % 组合成新节点
            new_node = struct('symbols', [node1.symbols, node2.symbols], 'prob', node1.prob + node2.prob);
            TREE(idx(1:2)) = [];
            TREE{end+1} = new_node;
        end
        cell_codes = huff_tree_codes;
    end
    
    % 打包成自定义字典格式
    huff_dict = struct('symbols', symbols, 'codes', {cell_codes});
    
    % 执行编码映射
    [~, loc] = ismember(img_vector, symbols);
    bit_stream_cell = cell_codes(loc);
    bit_stream = cell2mat(bit_stream_cell.').'; % 确保输出列向量
end

% function [bit_stream, huff_dict, img_size] = source_encode(img_matrix)
% % SOURCE_ENCODE 哈夫曼信源编码
% % 输入: img_matrix - 原始灰度图像矩阵 (uint8)
% % 输出: bit_stream - 压缩后的二进制比特流 (列向量)
% %       huff_dict  - 哈夫曼字典 
% %       img_size   - 原始图像尺寸
% 
%     img_size = size(img_matrix);
% 
%     % 1. 将图像转为一维双精度向量，供工具箱使用
%     img_vector = double(img_matrix(:)); 
% 
%     % 2. 统计所有出现过的像素值 (0-255)
%     symbols = unique(img_vector);
% 
%     % 3. 统计每个像素值出现的概率
%     counts = histcounts(img_vector, [symbols; max(symbols)+1]);
%     p = counts / sum(counts);
% 
%     % 4. 生成哈夫曼字典 (调用通信工具箱)
%     huff_dict = huffmandict(symbols, p);
% 
%     % 5. 执行哈夫曼编码
%     bit_stream = huffmanenco(img_vector, huff_dict);
% end