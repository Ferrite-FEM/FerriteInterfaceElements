@testset "InterfaceCellInterpolation" begin
    for (baseshape, shape) in ( (RefLine, RefQuadrilateral), (RefTriangle, RefPrism), (RefQuadrilateral, RefHexahedron) )
        for order in (1,2)
            IP   = Lagrange{baseshape, order, Nothing}
            base = Lagrange{baseshape, order}()
            @test InterfaceCellInterpolation(base) isa InterfaceCellInterpolation{shape, order, IP}
            ip = InterfaceCellInterpolation(base)
            @test Ferrite.nvertices(ip) == 2*Ferrite.nvertices(base)
            @test all(Ferrite.vertexdof_indices(ip) .== collect( (v,) for v in 1:Ferrite.nvertices(ip) ))
        end
    end
    base = Lagrange{RefQuadrilateral, 2}()
    ip = InterfaceCellInterpolation(base)

    @test getnbasefunctions(ip) == 18

    @test_throws ArgumentError FerriteInterfaceElements.get_interface_index(ip, :here, 10)
    @test_throws ArgumentError FerriteInterfaceElements.get_interface_index(ip, :there, 10)
    @test_throws ArgumentError FerriteInterfaceElements.get_interface_index(ip, :nowhere, 10)

    @test Ferrite.vertexdof_indices(ip) == ((1,),(2,),(3,),(4,),(5,),(6,),(7,),(8,))
    @test Ferrite.facedof_indices(ip) == ((1,2,3,4,9,10,11,12,17), (5,6,7,8,13,14,15,16,18))
    @test Ferrite.facedof_interior_indices(ip) == ((17,), (18,))
    @test Ferrite.edgedof_indices(ip) == ((1,2,9),(2,3,10),(3,4,11),(4,1,12),(5,6,13),(6,7,14),(7,8,15),(8,5,16))
    @test Ferrite.edgedof_interior_indices(ip) == ((9,),(10,),(11,),(12,),(13,),(14,),(15,),(16,))

    testcelltype = InterfaceCell{RefQuadrilateral, Line}
    expectedtype = InterfaceCellInterpolation{RefQuadrilateral, 1, Lagrange{RefLine,1,Nothing}}
    @test Ferrite.default_interpolation(testcelltype) isa expectedtype
    @test Ferrite.default_geometric_interpolation(Ferrite.default_interpolation(testcelltype)) isa VectorizedInterpolation{2, RefQuadrilateral, <:Any, expectedtype}
end
