function [ output ] = analytical_estimator( input, model , custom_options, draw_plot, debug )
%ANALYTICAL_ESTIMATOR Summary of this function goes here
%   Detailed explanation goes here
%#function lsqcurvefit

MAX_COUNT = 25;
COUNT_TEST = 5;

    try
        
        %% check if it is a POST or GET method
        method = getenv('REQUEST_METHOD');
        if 1 == 1 || strcmp(method,'POST')
            post = '';
            %fid = fopen('/dev/fd/0');
            fid = fopen('/home/dev/test_long');
            eof = 1;
            while eof == 1
                post_tmp = fgets(fid,Inf);
                if post_tmp == -1
                    eof = 0;
                else
                    post = strcat(post,post_tmp);
                end
            end
            input = qs2struct(post);
            fclose(fid);
        end
        %% print html header that tells it is json data
        printHeader( 0 );
        %
        %% builds time (x) and values (y) matrices
        time_s_array = textscan(input.time,'%s','delimiter',';','BufSize',length(input.time)+100);
        value_s_array = textscan(input.values,'%s','delimiter',';','BufSize',length(input.values)+100);
        len = length(time_s_array{1});
        time = [];
        values = [];
        for i = 1:len
            time_aux = str2num(char(time_s_array{1}(i)));
            values_aux = str2num(char(value_s_array{1}(i)));
            %
            padadd( time , time_aux );
            padadd(values, values_aux);
        end
        %% building string 
        % starts by converting string to json
        estimat = strrep(input.estimation, '%22' , '"');
        estimat = strrep(estimat, '%7B' , '{');
        estimat = strrep(estimat, '%7D' , '}');
        % reads json
        estimation = build_estimation( loadjson( estimat ) );
        %% Options for estimation
        options = optimset('DerivativeCheck','on','FinDiffType','central','Display','off');
        % options retrieved from build estimation
        options.MaxIter = estimation.optimization.options.maxiter;
        options.MaxFunEvals = estimation.optimization.options.maxfunevals;
        options.TolFun = estimation.optimization.options.tolfun;
        options.TolX = estimation.optimization.options.tolx;
        
        custom_fieldnames = fieldnames(custom_options);
        for j = 1:length(custom_fieldnames);
            options.(char(custom_fieldnames(j))) = custom_options.(char(custom_fieldnames(j)));
        end
        
        % sorting by parameters name (convention!)
        [res index] = sort(lower(estimation.parameters.names));
        %
        %% model (with parameters sorted by name)
        % parameters' name reflects what is defined in the application
        % params(1): A
        % params(2): lambda
        % params(3): miu
        %
        max_count = MAX_COUNT;
        count_test = COUNT_TEST;
        resnorm = Inf;
        ahat = [];
        output = [];
        beta0 = [];
        while max_count >= 0 && count_test >= 0
            %
            [ub,lb,beta0] = set_init_params(res, index, estimation );
            if debug
                fprintf(1,'b0: ');
                for j = 1:length(beta0)
                    fprintf(1,'%s:%f | ' , estimation.parameters.names{index(j)},beta0(j) );
                end
                fprintf(1,' start point for parameters\n');
            end
            try
                [ahat_t,resnorm_t,~,~,output_t,~,~] = lsqcurvefit(model , beta0 , time , values , lb , ub , options );
            catch err_sqr
                if debug
                   fprintf(1,'%2d: error!: %s\n' , max_count, err_sqr.message); 
                end
                max_count = max_count - 1;
                continue;
            end
            if debug
                fprintf(1,'%2d: ', max_count);
                for j = 1:length(ahat_t)
                    fprintf(1,'%s:%f | ' , estimation.parameters.names{index(j)},ahat_t(j));
                end
                fprintf(1,'(%f)\n' , resnorm_t);
            end
            if resnorm_t < resnorm
               resnorm = resnorm_t;
               ahat = ahat_t;
               output = output_t;
            end
            if all_params_changed(beta0,ahat_t)
                count_test = count_test - 1;
            else
                count_test = COUNT_TEST;
                max_count = max_count - 1;    
            end
        end

    catch err
        msg = sprintf('{"error": "%s" }\n',err.message);
        fprintf(1,'%s',msg);
        output = -1;
        return;
    end
    
    if isempty( ahat )
        fprintf(1,'%s\n','{"Error": "could not determine parameters, check range and try again." }');
        output = -1;
        return;
    end
    
    try
        fprintf(1,'{\n');

        for j = 1:length(res)
           fprintf( 1 , '\t"%s": %f' , estimation.parameters.names{index(j)} , ahat(j) );
           fprintf(1,',\n');
        end
        fprintf(1,'\t"o": %.14f\n' , resnorm);
        fprintf(1,'}\n');
        %
        % if plot argument is true
        if draw_plot
            xrange= min(time):.01:max(time);
            hold on;
            [~,len] = size(time);
            for j = 1:len
                scatter(time(:,j),values(:,j));
            end
            plot(xrange,model(ahat,xrange),'r');
            hold off;
        end
    catch err
        msg = sprintf('"error": "%s" }\n',err.message);
        fprintf(1,'%s',msg);
        output = -1;
        return;
    end
    output = 0;
        
end

