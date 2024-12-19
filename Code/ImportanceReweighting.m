function b = ImportanceReweighting(probability, predicted_class, positive_noise, negative_noise)
    if (predicted_class == 1)
        b = (probability - negative_noise) / ((1 - positive_noise - negative_noise) * probability);
    else
        b = (probability - positive_noise) / ((1 - positive_noise - negative_noise) * probability);
    end
end

