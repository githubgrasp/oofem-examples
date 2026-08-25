%test imperfection
clear all;
%syms t0 x L 

%Idea is to plot the deformed shape of specimen so that it can be fet into
%oofem
nEl = 5;
t0 = 0.001;

%First calculate the length in x-direction using suggestion from chatgpt
L_target = pi;  % Target arc length

% Define the integrand for the arc length
integrand = @(x) sqrt(1 + (t0^2) * (cos(x).^2));

% Define the function to find the difference
arc_length_diff = @(b) integral(integrand, 0, b) - L_target;

% Use fzero to find the root, with an initial guess
b_initial_guess = 2;  % You can adjust this guess
b_value = fzero(arc_length_diff, b_initial_guess);


t = 0:L_target/nEl:L_target;
y = t0*sin(t);
x=t/(L_target/b_value);

outputFile = fopen('output.dat','w');
plot(x,y,'-');
formatSpec = 'node %d coords 3 %f %f 0.\n';
for i=1:nEl+1
    fprintf(outputFile,formatSpec, i, x(i), y(i));
end
