
using Test
urls = Vector{AbstractString}(["https://docs.julialang.org/en/v1/"])
url = urls[1]
queue = Vector{AbstractString}()

@testset "check robots.txt" begin
    result, sitemap_queue = check_robots_txt("*", url)
    @test result == true
end

@testset "HTTP get" begin
    @test HTTP.get(url) != nothing
end

@testset "get_urls!" begin
    get_urls!(url, queue)
    @test length(queue) > 1
end

@testset "parse & roll_up" begin
    parsed_blocks = parse_url_to_blocks(url)
    @test length(parsed_blocks) > 0
    SEP = "<SEP>"
    docs_, sources_ = roll_up_chunks(parsed_blocks, url; separator=SEP)
    @test length(docs_) > 0 && length(sources_) > 0 && docs_[1] != nothing && sources_[1] != nothing
end

@testset "overall test" begin
    chunks, sources = process_paths(url)
    @test length(chunks) > 0 && length(sources) > 0 && chunks[1] != nothing && sources[1] != nothing

end
