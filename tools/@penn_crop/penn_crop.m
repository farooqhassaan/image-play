classdef penn_crop
    properties (Access = private)
        split
        dir
        ind2sub
        visible
        part
        seqId
        nFrame
        nPhase
        seqLength
        inputRes
        outputRes
        img
    end
    methods
        % constructor
        function obj = penn_crop(opt, split)
            obj.split = split;
            obj.dir = fullfile(opt.data, 'frames');
            assert(exist(obj.dir,'dir') == 7, ['directory does not exist: ' obj.dir]);
            % load annotation
            annot_file = fullfile(opt.data, [split '.h5']);
            obj.ind2sub = permute(hdf5read(annot_file,'ind2sub'),[2 1]);
            obj.part = permute(hdf5read(annot_file,'part'),[3 2 1]);
            % preprocess annotation
            [obj.seqId, obj.nFrame] = preproAnno(obj);
            % get phase number and LSTM sequence length
            obj.nPhase = opt.nPhase;
            obj.seqLength = opt.seqLength;
            % get input and output resolution
            obj.inputRes = opt.inputRes;
            obj.outputRes = opt.outputRes;
            % load lib
            obj.img = img();
        end
        
        % get seq id and num of frames
        [seqId, nFrame] = preproAnno(obj);
        
        % get phase sequence in global index (ind2sub)
        ind = getSeq(obj, i);
        
        % get image path
        pa = imgpath(obj, idx);
        
        % load image
        img = loadImage(obj, idx);
        
        % get center and scale
        [center, scale] = getCenterScale(obj, img);
        
        % get dataset size
        out = size(obj);
        
        [input, hmap, proj, gtpts, center, scale] = get(obj, idx);
        
        [sid, fid] = getSeqFrId(obj, idx);
        
        % get sampled indices; for prediction and visualization
        sidx = getSampledIdx(obj);
    end
end