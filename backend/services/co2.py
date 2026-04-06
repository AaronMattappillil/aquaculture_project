def estimate_co2(ph: float, temperature: float, turbidity: float) -> float:
    kh  = (turbidity * 0.01) + (temperature * 0.05)
    co2 = 3.0 * (kh * (10 ** (7.0 - ph)))
    return round(co2, 2)
