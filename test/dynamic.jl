
@testset "Dynamic Weights" begin
    @testset "Known V, Unknown W" begin
        Y = [[-0.112, 1.98, -2.28, 0.771, 21.2, 21.5],
             [-5.18, -2.44, -8.11, 0.165, 15.6, 18.6],
             [-19.3, -21.7, -22.0, -6.82, 13.6, 28.7],
             [-45.5, -32.2, -41.6, -35.0, 12.0, 27.3],
             [-64.4, -52.6, -70.3, -56.5, 2.44, 9.62],
             [-93.9, -77.0, -92.8, -75.8, -2.38, -1.88]]
        η = hcat([0.45, 0.45, 0.40, 0.30, 0.17, 0.05],
                 [0.45, 0.45, 0.40, 0.30, 0.17, 0.05],
                 [0.10, 0.10, 0.20, 0.40, 0.66, 0.90])

        F = [1. 0. 0.; 0. 1. 0.]
        G = [1. 0. 1.; 0. 1. 1.; 0. 0. 1.]
        V = Symmetric(diagm([12., 12.]))

        # Filter
        a, R, m, C = kfilter(Y, F, G, V, η, 0.8)

        @test a[end] ≈ [-27.190627146772364, -18.995342748051463, -4.916889343012473]
        @test R[end][1,3] ≈ R[end][2,3]
        @test R[end][3,3] ≈ 1.169478699932751
        @test m[end] ≈ [-18.453716253522465, -11.895375806382145, -2.5258277006501766]
        @test C[end][3,3] ≈ 0.6027170489902908

        # Smoother
        s, S = ksmoother(G, a, R, m, C)

        @test s[1] ≈ [-2.030157490822254, 3.400235808546456, -2.892548710163002]
        @test S[1][1,3] ≈ S[1][2,3]
        @test S[1][1,2] ≈ 1.9434098177645183

        # Fitted
        f, Q = fitted(F, V, s, S)

        @test f[1] ≈ [-2.030157490822254, 3.400235808546456]
        @test Q[1][1,1] ≈ Q[1][2,2]
        @test Q[end][1,2] ≈ 2.121050612190616

        # Forecast
        fh, Qh = forecast(F, G, V, 0.8, m[end], C[end], 6)

        @test fh[end] ≈ [-33.60868245742352, -27.0503420102832]
        @test Qh[end][1,1] ≈ Qh[end][2,2]
        @test Qh[end][1,2] ≈ 137.1312402019029
    end

    @testset "Unknown V, Unknown W" begin
        Y = [[-1.07, -4.79, 8.75, -3.38, 101.0, 95.3],
             [1.77, -4.83, -0.701, 8.53, 95.6, 91.6],
             [-2.44, 1.05, -1.99, -10.2, 110.0, 98.4],
             [-22.3, -25.6, -18.9, -27.4, 109.0, 116.0],
             [-66.0, -71.0, -64.1, -76.8, 142.0, 131.0],
             [-137.0, -138.0, -129.0, -138.0, 162.0, 163.0]]
        η = hcat([0.45, 0.475, 0.35, 0.20, 0.10, 0.025],
                 [0.45, 0.475, 0.35, 0.20, 0.10, 0.025],
                 [0.10, 0.150, 0.30, 0.60, 0.80, 0.950])

        F = [1. 0. 0.; 0. 1. 0.]
        G = [1. 0. 1.; 0. 1. 1.; 0. 0. 1.]

        # Estimate
        θ, Σ = estimate(Y, F, G, η, 0.8)

        @test θ[end] ≈ [128.5975140749007, 125.88516545696008, 25.250530953592737]
        @test diag(Σ) ≈ [17002.330502123168, 17452.4131082849]

        # Evolutional Covariances
        Σₑ = evolutional_covariances(Y, F, G, Σ, η, 0.8)

        @test Σₑ[end][:,3] ≈ [422.8068930004123, 424.1022162558545, 127.25615793643713]

        # Fitted
        f, Q = fitted(F, Σ, θ, Σₑ)

        @test f[1] ≈ [6.910174516807798, 4.197813682749192]
        @test diag(Q[1]) ≈ [23077.42980723912, 23582.512590829927]
        @test Q[1][1,2] ≈ 4270.747555928984

        # Forecast
        fh, Qh = forecast(F, G, Σ, 0.8, θ[end], Σₑ[end], 10)

        @test fh[end] ≈ [381.102823610828, 378.3904749928874]
        @test Qh[end][1,2] / (sqrt(Qh[end][1,1]) * sqrt(Qh[end][2,2])) ≈ 0.8104078439438087
        @test Qh[end][1,1] ≈ 163819.5096757467
    end
end