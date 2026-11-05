import Foundation
@main enum NetworkPolicyTests {
 static func main() {
  let valid = URL(string:"https://huggingface.co" + FieldnotesLocalOnlyHTTPPolicy.modelPath)!
  precondition(FieldnotesLocalOnlyHTTPPolicy.allows(method:"GET",url:valid,hasBody:false))
  precondition(FieldnotesLocalOnlyHTTPPolicy.allows(method:"HEAD",url:valid,hasBody:false))
  precondition(!FieldnotesLocalOnlyHTTPPolicy.allows(method:"POST",url:valid,hasBody:false))
  precondition(!FieldnotesLocalOnlyHTTPPolicy.allows(method:"GET",url:valid,hasBody:true))
  for address in ["http://huggingface.co" + valid.path,"https://huggingface.co.evil.test" + valid.path,"https://huggingface.co/api/v2/sdk/telemetry/llm","https://user@huggingface.co" + valid.path] {
   precondition(!FieldnotesLocalOnlyHTTPPolicy.allows(method:"GET",url:URL(string:address)!,hasBody:false))
  }
  precondition(FieldnotesLocalOnlyHTTPPolicy.allowsRedirect(from:valid,to:URL(string:"https://cas-bridge.xethub.hf.co/file")))
  precondition(!FieldnotesLocalOnlyHTTPPolicy.allowsRedirect(from:valid,to:URL(string:"https://xethub.hf.co.evil.test/file")))
  precondition(!FieldnotesLocalOnlyHTTPPolicy.allowsRedirect(from:valid,to:URL(string:"http://cas-bridge.xethub.hf.co/file")))
  print("11 network policy checks passed")
 }
}
