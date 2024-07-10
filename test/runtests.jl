
using Test
using HTTP, Gumbo, AbstractTrees, URIs
using Gumbo: HTMLDocument, HTMLElement
using EzXML
using PromptingTools
const PT = PromptingTools
const RT = PromptingTools.Experimental.RAGTools
using LinearAlgebra, Unicode, SparseArrays
using HDF5
using Tar
using Inflate

using SHA
using Serialization, URIs

include("..\\src\\crawl.jl")
include("..\\src\\extract_urls.jl")
include("..\\src\\parser.jl")
include("..\\src\\preparation.jl")
urls = Vector{AbstractString}(["https://docs.julialang.org/en/v1/"])
url = urls[1]
queue = Vector{AbstractString}()

@testset "check robots.txt" begin
    @test HTTP.get(url) != nothing

    result, sitemap_queue = check_robots_txt("*", url)
    @test result == true
end

@testset "crawl" begin
    hostname_url_dict = crawl(urls)
    @test length(hostname_url_dict) > 0
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
