function r = Risk(probabilities, predicted_classes, real_classes, positive_noise, negative_noise)
   n = size(probabilities, 1);
   sum = 0;
   for i=1:n
       sum = sum + ImportanceReweighting(probabilities(i), predicted_classes(i), positive_noise, negative_noise) * HingeLoss();
   end
end

