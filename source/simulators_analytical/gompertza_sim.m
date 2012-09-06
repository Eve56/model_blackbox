function [ output ] = gompertza_sim( test_data , draw_plot )
%GOMPERTZA_SIM Summary of this function goes here
%   Detailed explanation goes here
    if nargin > 0 && test_data
        s = 'A=7.050965&lambda=88.318105&miu=0.014470&N=1.5&end=467';
        s = 'miu=7.050965&lambda=88.318105&A=0.01447&end=467.50000000000006';
        s = 'miu=0.01447&lambda=88.318105&A=7.050965&end=467.50000000000006';
        input = qs2struct(s);
    else
        input = qs2struct(getenv('QUERY_STRING'));    
    end
    
    try
        %
        params(1) = str2double( input.A );
        params(2) = str2double( input.lambda );
        params(3) = str2double( input.miu );
        params(4) = str2double( input.N );
        TimeEnd = timeStep( str2double( input.end ) );
        %
        model = @gompertza;
        
        values = model(params , TimeEnd);
        output = [ transpose(TimeEnd) transpose(values) ];
        
        if nargin > 1 && draw_plot
            plot(TimeEnd,values);
        end
        printJson(output);
    catch err
        msg = sprintf('{ "error": "%s" }\n',err.message);
        printHeader(length(msg));
        fprintf(1,'%s',msg);    
    end

end

