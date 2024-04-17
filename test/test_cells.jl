@testset "InterfaceCell" begin
    for (here, there, shape) in (
            (         Line((1,2)),            Line((3,4)),   RefQuadrilateral), 
            (QuadraticLine((1,2,5)), QuadraticLine((3,4,6)), RefQuadrilateral),
            (         Triangle((1,2,3)),                Triangle((4,5,6)),          RefPrism), 
            (QuadraticTriangle((1,2,3,7,8,9)), QuadraticTriangle((4,5,6,10,11,12)), RefPrism),
            (         Quadrilateral((1,2,3,4)),                        Quadrilateral((5,6,7,8)),                RefHexahedron), 
            (QuadraticQuadrilateral((1,2,3,4,9,10,11,12,17)), QuadraticQuadrilateral((5,6,7,8,13,14,15,16,18)), RefHexahedron)
            ) # The nodes have been chosen as the numbers representing their expected ordering
        C  = typeof(here)

        @test InterfaceCell{shape, C}(here, there) isa InterfaceCell{shape, C}
        @test InterfaceCell(here, there) isa InterfaceCell{shape, C}
        cell = InterfaceCell(here, there)

        @test Ferrite.nvertices(cell) == Ferrite.nvertices(here) + Ferrite.nvertices(there)
        @test Ferrite.nfaces(cell) == 2
        @test Ferrite.nnodes(cell) == Ferrite.nnodes(here) + Ferrite.nnodes(there)
        
        @test Ferrite.get_node_ids(cell) == ntuple(i -> i, Ferrite.nnodes(cell))
        @test Ferrite.vertices(cell) == (Ferrite.vertices(here)..., Ferrite.vertices(there)...)
        @test Ferrite.faces(cell) == (Ferrite.vertices(here), Ferrite.vertices(there))
    end
    #=
    here  = QuadraticQuadrilateral((1,2,3,4,9,10,11,12,17)), 
    there = QuadraticQuadrilateral((5,6,7,8,13,14,15,16,18))
    expected = ((:here,1),  (:here,2),  (:here,3),  (:here,4),
                (:there,1), (:there,2), (:there,3), (:there,4),
                (:here,5),  (:here,6),  (:here,7),  (:here,8),
                (:there,5), (:there,6), (:there,7), (:there,8),
                (:here,9), 
                (:there,9))
    @test FerriteInterfaceElements.get_sides_and_base_indices(InterfaceCell(here, there))   == expected
    @test FerriteInterfaceElements.get_sides_and_base_indices(here, there) == expected
    =#
end

@testset "Inserting interfaces in 2D" begin
    grid = generate_grid(Triangle, (2,2), Vec((-1.0,-1.0)), Vec((1.0,1.0)))
    
    #  7----8----9
    #  | \6 | \8 |
    #  | 5\ | 7\ |
    #  4----5----6
    #  | \2 | \4 |
    #  | 1\ | 3\ |
    #  1----2----3

    addcellset!(grid, "bottom",  x -> x[2] ≤ 0)
    addcellset!(grid, "top",     x -> x[2] ≥ 0)
    addcellset!(grid, "top left",  x -> x[1] ≤ 0 && x[2] ≥ 0)
    addcellset!(grid, "top right", x -> x[1] ≥ 0 && x[2] ≥ 0)

    newcells = create_interface_cells!(grid, "bottom", "top")
    @test newcells[1].nodes == (12,10,6,5) # bottom: 4 -> 11, 5 -> 10, 6 -> 12
    @test newcells[2].nodes == (10,11,5,4)
    for (i, n) in enumerate(((1,2,11), (2,10,11), (2,3,10), (3,12,10), (4,5,7), (5,8,7), (5,6,8), (6,9,8)))
        @test grid.cells[i].nodes == n
    end
    grid = Grid(vcat(grid.cells, newcells), grid.nodes; cellsets=grid.cellsets)

    newcells = create_interface_cells!(grid, "top left", "top right")
    @test newcells[1].nodes == (13,14,5,8) # top left: 5 -> 13, 8 -> 14
    for (i, n) in enumerate(((1,2,11), (2,10,11), (2,3,10), (3,12,10), (4,13,7), (13,14,7), (5,6,8), (6,9,8), (12,10,6,5), (10,11,13,4)))
        @test grid.cells[i].nodes == n
    end
end