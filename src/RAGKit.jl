module RAGKit
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
# using Regex

# using Robots

include("parser.jl")
include("crawl.jl")
include("extract_urls.jl")
include("preparation.jl")

include("make_embeddings.jl")
export make_embeddings


end