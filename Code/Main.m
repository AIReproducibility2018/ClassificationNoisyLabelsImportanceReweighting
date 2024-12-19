% Input arguments
dataset = "diabetis";
p_positive = 0.2;
p_negative = 0.2;
random_seed = 1;
output_folder = "Results/";

rng('default')
rng(random_seed);

% Load data
data = eval(dataset);

x = data.x;
y = data.t;
combined = [y x];

training_sets = [];
test_sets = [];

folder = strcat(output_folder, dataset, "_0", int2str(p_positive*10), "_0", int2str(p_negative*10), "/");
if ~exist(folder, 'dir')
    mkdir(char(folder));
end

% Partition dataset into test and training
for i=1:10
    training_size = round(size(combined, 1) * 0.75);
    test_size = size(combined, 1) - training_size;
    
    temp = combined;
    
    training_rows = randperm(size(combined, 1), training_size);
    training_set = combined(training_rows, :);
    
    training_file_path = strcat(folder, int2str(i), ".csv");
    training_file = fopen(training_file_path, 'w');
    fprintf(training_file, "%s;%s\n", "Index", "Flipped");
    
    % Add noise to training set according to noise rates p0 and p1
    for j=1:size(training_rows, 2)
        flipped = 'N';
        r = rand;
        if training_set(j, 1) == -1
            if r <= p_negative
                training_set(j, 1) = 1;
                flipped = 'Y';
            end
        else
            if r <= p_positive
                training_set(j, 1) = -1;
                flipped = 'Y';
            end
        end
        fprintf(training_file, "%i;%s\n", training_rows(j), flipped);
    end
    
    fclose(training_file);
    
    training_sets = [training_sets {training_set}];
    
    temp(training_rows, :) = [];
    test_set = temp;
    test_sets = [test_sets {test_set}];
end

estimated_positive_noise_rates = [];
estimated_negative_noise_rates = [];

output_file_path = strcat(folder, "results.csv");
results_file = fopen(output_file_path, 'w');
fprintf(results_file, '%s;%s\n', "Estimated positive noise", "Estimated negative noise");

% Estimate noise rates
for i=1:size(training_sets, 2)
    training_set = training_sets{i};
    
    % Estimate P(Y|X)
    n = size(training_set, 1);
    positive_samples = 0.0;
    negative_samples = 0.0;
    positive_numerator_samples = [];
    negative_numerator_samples = [];
    denominator_samples = [];
    
    for j=1:n
        sample = training_set(j,:);
        class = sample(1);
        sample(1) = [];
        denominator_samples = [denominator_samples; sample];
        if class == 1
            positive_samples = positive_samples + 1;
            positive_numerator_samples = [positive_numerator_samples; sample];
        else
            negative_samples = negative_samples + 1;
            negative_numerator_samples = [negative_numerator_samples; sample];
        end
    end
    denominator_samples = transpose(denominator_samples);
    positive_numerator_samples = transpose(positive_numerator_samples);
    negative_numerator_samples = transpose(negative_numerator_samples);
    positive_estimated_r = KLIEP(denominator_samples, positive_numerator_samples);
    negative_estimated_r = KLIEP(denominator_samples, negative_numerator_samples);
    
    p_positive = positive_samples / n;
    p_negative = negative_samples / n;
    
    positive_probabilities = [];
    negative_probabilities = [];
    
    for j=1:n
        positive_probabilities = [positive_probabilities; positive_estimated_r(j)*p_positive];
        negative_probabilities = [negative_probabilities; negative_estimated_r(j)*p_negative];
    end
    
    % Estimate noise rates
    estimated_positive_noise = 1.0;
    estimated_negative_noise = 1.0;
    for j=1:n
        if (positive_probabilities(j) < estimated_negative_noise)
            estimated_negative_noise = positive_probabilities(j);
        end
        if (negative_probabilities(j) < estimated_positive_noise)
            estimated_positive_noise = negative_probabilities(j);
        end
    end
    
    fprintf(results_file, '%f;%f\n', estimated_positive_noise, estimated_negative_noise);
    
    estimated_positive_noise_rates = [estimated_positive_noise_rates; estimated_positive_noise];
    estimated_negative_noise_rates = [estimated_negative_noise_rates; estimated_negative_noise];
    
end

fclose(results_file);

positive_noise_mean = mean(estimated_positive_noise_rates);
positive_noise_std = std(estimated_positive_noise_rates);
disp("Estimated noise rate of positive class " + positive_noise_mean + " +- " + positive_noise_std)

negative_noise_mean = mean(estimated_negative_noise_rates);
negative_noise_std = std(estimated_negative_noise_rates);
disp("Estimated noise rate of negative class " + negative_noise_mean + " +- " + negative_noise_std)


