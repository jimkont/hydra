-- | A proxy for the Hydra kernel, i.e. the code which must be present in every Hydra implementation, and can be imported as a unit.

module Hydra.Kernel (
  module Hydra.Adapters.Coders,
  module Hydra.Adapters.Literal,
  module Hydra.Adapters.Term,
  module Hydra.Adapters.Utils,
  module Hydra.Basics,
  module Hydra.Coders,
  module Hydra.Common,
  module Hydra.Compute,
  module Hydra.Core,
  module Hydra.CoreDecoding,
  module Hydra.CoreEncoding,
  module Hydra.CoreLanguage,
  module Hydra.Graph,
  module Hydra.Grammar,
  module Hydra.Lexical,
  module Hydra.Mantle,
  module Hydra.Kv,
  module Hydra.Module,
  module Hydra.Monads,
  module Hydra.Phantoms,
  module Hydra.Reduction,
  module Hydra.Rewriting,
  module Hydra.Types.Inference,
  -- module Hydra.Util.Codetree.Ast,
  module Hydra.Util.Debug,
  module Hydra.Util.Formatting,
--  module Hydra.Util.GrammarToModule,
  module Hydra.Util.Sorting,
  module Hydra.Workflow,
) where

import Hydra.Adapters.Coders
import Hydra.Adapters.Literal
import Hydra.Adapters.Term
import Hydra.Adapters.Utils
import Hydra.Basics
import Hydra.Coders
import Hydra.Common
import Hydra.Compute
import Hydra.Core
import Hydra.CoreDecoding
import Hydra.CoreEncoding
import Hydra.CoreLanguage
import Hydra.Graph
import Hydra.Grammar
import Hydra.Lexical
import Hydra.Mantle
import Hydra.Kv
import Hydra.Module
import Hydra.Monads
import Hydra.Phantoms
import Hydra.Reduction
import Hydra.Rewriting
import Hydra.Types.Inference
-- import Hydra.Util.Codetree.Ast
import Hydra.Util.Debug
import Hydra.Util.Formatting
--import Hydra.Util.GrammarToModule
import Hydra.Util.Sorting
import Hydra.Workflow
