clear all;
clc;
cycle = 1000;
T = zeros(1,cycle);
for i = 1:cycle
    N = randi(100,1,1e6);
    con = zeros(1,100);
    num = 0;
    t = 0;
    flag = 1;
    for j=1:101
        t = t + 1;
       if flag == 1
          if con(N(t))==1
              C = N(t);
              flag = 0;
              num = t-1;
          else
              con(N(t)) = 1;
          end
       end
    end
    flag = 0;    
    while num < 99
        t=t+1;
        if N(t)==C
            num = num + flag;
            flag = 0;
        else
            if con(N(t))==0
                if flag==0
                    flag = 1;
                    con(N(t)) = 1;
                end
            end
        end  
    end
    T(i) = t;
end
disp(sum(T)/cycle);
f = zeros(1,1e6);
for i = 1:1e6
    f(i) = sum(T<i)/cycle;
end
semilogx(f(1:1e6));