function l = HingeLoss(prediction, real_class)
    l = max(0, 1 - prediction*real_class);
end

