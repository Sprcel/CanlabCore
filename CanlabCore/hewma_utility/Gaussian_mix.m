function [ind,ind2,stats] = Gaussian_mix(x,niter,basepts,verbose,doplot, doplot2)% Two-Gaussian mixture model%% :Usage:% ::%%     [ind,ind2,stats] = Gaussian_mix(x,niter,basepts,verbose,doplot, doplot2)%% :Inputs:%%   **x:**%        data%%   **iter:**%        number of iterations%%   **basepts:**%        number of baseline pts at start of run. The modal class in the%        baseline period is defined as the 0-class%% :Outputs:%%   **ind:**%        indicator function of class belonging%%   **ind2:**%        indicator function of class belonging where 3 consecutive points%        are needed to switch states%%   **mu:**%        mean vector%%   **sigma:**%        standard deviation%%   **p:**%        probability that latent class random variable (delta) is equal%        to [0,1]%% :Examples:% ::%%    [ind,ind2,stats] = Gaussian_mix(linear_detrending(dat),20);%    % dat is n subjects by t time points%    % plotting is on%%    % Simulated data%    r = normrnd(1, 1, 200, 1); r(1:50) = r(1:50) + normrnd(3, 1, 50, 1);%    [ind, ind2, stats] = Gaussian_mix(r, 50, [], 0, 1);% % We recommend 50 iterations% ..    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    %    % Set up inputs    %    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% ..    if ~(exist('doplot')==1) || isempty(doplot), doplot = 1; end    if ~(exist('doplot2')==1) || isempty(doplot2), doplot2 = 1; end    if ~(exist('verbose')==1) || isempty(verbose), verbose = 1; end    if ~(exist('basepts')==1) || isempty(basepts), basepts = 1:length(x); end    % make sure it's a column vector or vectors    if size(x,1) ~= length(x), x = x'; end    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    %    % Iterative mode    %    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    if size(x,2) > 1        % multiple data vectors, run this function iteratively        IND = []; IND2 = [];        verbose = 0;        if doplot, nrows = ceil(sqrt(size(x,2))); tor_fig(nrows,nrows); end        for datavec = 1:size(x,2)            if doplot, subplot(nrows,nrows,datavec);  end            [IND(:,datavec),IND2(:,datavec),stats(datavec)] = Gaussian_mix(x(:,datavec),niter,basepts,verbose,doplot);        end        % save group stats/output        ind = IND; ind2 = IND2;        S.cp = cat(1,stats.cp);        S.cnt = cat(1,stats.cnt);        S.tot = cat(1,stats.tot);        S.longest = cat(1,stats.longest);        S.firstlen = cat(1,stats.firstlen);        S.totaldur = cat(1,stats.totaldur);        S.mu = cat(2,stats.mu);        S.sigma = cat(2,stats.sigma);        S.p = cat(1,stats.p);        S.ind2 = IND2;        S.ind = ind;        S.cpmean = nanmean(S.cp);        S.meancnt = mean(S.cnt);        S.meantot = mean(S.tot);        S.meantotaldur =  mean(S.totaldur);        S.meanlongest = mean(S.longest);        S.meanfirst = mean(S.firstlen);        ind = mean(IND2')';     % group prob. of activation state        stats = S;        if doplot            % group plot            tor_fig; plot(ind,'k','LineWidth',2);            hold on; plot(S.cpmean,ind(round(S.cpmean)),'ko','MarkerSize',12,'MarkerFaceColor',[.5 .5 .5]);            xlabel('Time (images)'); ylabel('Probability of active state.');        end        return    end    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    %    % Initial values for EM-algorithm    %    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    n = length(x);    gam =zeros(n,2);    p = [0.5 0.5];                      % probability that delta is [0,1]    %mu = normrnd(0,1,1,2);              % means of Gaussian    mu = zeros(1,2);    mu(1) = min(x);    mu(2) =max(x);    sigma = zeros(1,1,2);               % covariance matrices    for i=1:2,        sigma(:,:,i) = std(x);    end    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    %    % EM -algorithm - repeat niter times    %    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    if verbose,  fprintf(1,'iteration %03d',0); end    for t=1:niter,        if verbose, fprintf(1,'\b\b\b%03d',t); end        % E-step        for i=1:2,            gam(:,i) = p(i)*det(sigma(:,:,i))^(-0.5)*exp(-0.5*sum((x'-repmat(mu(:,i),1,n))'*inv(sigma(:,:,i)).*(x'-repmat(mu(:,i),1,n))',2));        end        gam = gam./repmat(sum(gam,2),1,2);            % Normalize        % M-step        for i=1:2,            mu(:,i) = (x'*gam(:,i))./sum(gam(:,i));                                                               % Update mean            ind = (gam>0.5);            dev = x-repmat(mu(:,i),n,1);            sigma(:,:,i) = dev' *(gam(:,i).* dev) ./ sum(gam(:,i));           % Update covariance            p(i) = mean(gam(:,i));                                                                                % Update probability        end        pooleds = sigma(:,:,1).*p(1) + sigma(:,:,2).*p(2);        sigma(:,:,1:2) = pooleds;    end    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    %    % Classify points    %    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    ind = (gam>0.5);    [a,b]=max(mu);    % Classify points using 3 consecutive alternate states in order to    % switch states    ind2 = zeros(n,1);    state = 0;    len = 3;    for i=1:(length(ind(:,b))-(len-1)),        if (state == 0),            if(sum(ind(i:(i+(len-1)),b)) == len),                state = 1;            end;        elseif (state == 1),            if(sum(ind(i:(i+(len-1)),b)) == 0),                state = 0;            end;        end;        ind2(i) = state;    end;    ind2((length(ind(:,b))-(len-1)):end) = state;    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    %    % re-format output and do baseline pts.    %    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    ind = ind(:,1) - ind(:,2);    %ind2 = ind2(:,1) - ind2(:,2);    % wh is the class number (0 = class #1, 1 = class #2) of the most frequent    % baseline class    classes = [0 1];    wh = [sum(ind2(1:basepts) == 0) sum(ind2(1:basepts) == 1)]; wh = find(wh==max(wh)); wh = wh(1);    baseclass = classes(wh);    % 0 or 1    whbase = find(ind2 == baseclass);    whactive = find(ind2 ~= baseclass);    % define so that base class is 0, active class is 1    ind2(whbase) = 0; ind2(whactive) = 1;    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    %    % output stats and stats on runs    %    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    stats.cp = find(ind2);  % first point in active state -- CP estimate    if isempty(stats.cp), stats.cp = NaN;    else        stats.cp = stats.cp(1);    end    [stats.cnt,stats.tot,lenmat] = cnt_runs(ind2);    stats.longest = max(lenmat); stats.firstlen = lenmat(1);    stats.totaldur = find(ind2);    if isempty(stats.totaldur) || length(stats.totaldur) < 2, stats.totaldur = 0;    else        stats.totaldur = stats.totaldur(end) - stats.totaldur(1);    end    stats.mu = mu'; stats.sigma = squeeze(sigma); stats.p = p; stats.gam = gam;    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    %    % Plot results    %    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    if doplot        xx = 1:length(x);        hold off;        plot(xx,x,'k','LineWidth',1);        hold on;        wh = find(~ind2); xtmp = x; xtmp(wh) = NaN;        plot(xx,xtmp,'b','LineWidth',2);        wh = find(ind2);xtmp = x; xtmp(wh) = NaN;        plot(xx,xtmp,'g','LineWidth',2);        %plot(ind2,'r','LineWidth',2);        %axis([0 length(ind) -0.1 1.1])    end    if doplot2        [h, x] = hist(x, ceil(length(x) ./ 5));        h1 = normpdf(x, stats.mu(1), stats.sigma(1));        h2 = normpdf(x, stats.mu(2), stats.sigma(2));        stats.cnt1 = sum(ind > 0);        stats.cnt2 = sum(ind < 0);        try            h1 = moving_average('gaussian', h1', 8)';            h2 = moving_average('gaussian', h2', 8)';        catch            disp('problem with moving average')        end                h1 = stats.cnt1 .* h1 ./ sum(h1);        h2 = stats.cnt2 .* h2 ./ sum(h2);        create_figure('Gaussian mixture plot');        plot(x, h, 'k', 'LineWidth', 2);        hold on;        plot(x, h1, 'r', 'LineWidth', 2);        plot(x, h2, 'b', 'LineWidth', 2);    end    return