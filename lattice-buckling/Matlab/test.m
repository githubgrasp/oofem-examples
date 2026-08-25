% Constants
t0 = 0.1;
L_target = pi;  % Target arc length

% Define the integrand for the arc length
integrand = @(x) sqrt(1 + (t0^2) * (cos(x).^2));

% Define the function to find the difference
arc_length_diff = @(b) integral(integrand, 0, b) - L_target;

% Use fzero to find the root, with an initial guess
b_initial_guess = 2;  % You can adjust this guess
b_value = fzero(arc_length_diff, b_initial_guess);

% Display the result
disp(['The value of b is: ', num2str(b_value)]);