import AppKit
let root = CommandLine.arguments[1]
let assets = root + "/ios/Runner/Assets.xcassets/AppIcon.appiconset"
let data = try Data(contentsOf: URL(fileURLWithPath: assets + "/Contents.json"))
let manifest = try JSONSerialization.jsonObject(with: data) as! [String:Any]
let entries = manifest["images"] as! [[String:String]]
func render(_ size:Int, _ path:String) throws {
 let space=CGColorSpaceCreateDeviceRGB()
 let ctx=CGContext(data:nil,width:size,height:size,bitsPerComponent:8,bytesPerRow:0,space:space,bitmapInfo:CGImageAlphaInfo.noneSkipLast.rawValue)!
 ctx.scaleBy(x:CGFloat(size)/1024,y:CGFloat(size)/1024)
 ctx.setFillColor(CGColor(red:24/255,green:60/255,blue:50/255,alpha:1));ctx.fill(CGRect(x:0,y:0,width:1024,height:1024))
 ctx.setFillColor(CGColor(red:216/255,green:245/255,blue:139/255,alpha:1))
 // Three leaves form a growing bloom. Coordinates are independent of output size.
 let left=CGMutablePath();left.move(to:CGPoint(x:491,y:440));left.addCurve(to:CGPoint(x:253,y:674),control1:CGPoint(x:310,y:425),control2:CGPoint(x:236,y:519));left.addCurve(to:CGPoint(x:491,y:440),control1:CGPoint(x:412,y:690),control2:CGPoint(x:501,y:593));left.closeSubpath();ctx.addPath(left);ctx.fillPath()
 let right=CGMutablePath();right.move(to:CGPoint(x:533,y:440));right.addCurve(to:CGPoint(x:771,y:674),control1:CGPoint(x:714,y:425),control2:CGPoint(x:788,y:519));right.addCurve(to:CGPoint(x:533,y:440),control1:CGPoint(x:612,y:690),control2:CGPoint(x:523,y:593));right.closeSubpath();ctx.addPath(right);ctx.fillPath()
 let top=CGMutablePath();top.move(to:CGPoint(x:512,y:579));top.addCurve(to:CGPoint(x:512,y:823),control1:CGPoint(x:410,y:668),control2:CGPoint(x:438,y:753));top.addCurve(to:CGPoint(x:512,y:579),control1:CGPoint(x:586,y:753),control2:CGPoint(x:614,y:668));top.closeSubpath();ctx.addPath(top);ctx.fillPath()
 ctx.setStrokeColor(CGColor(red:216/255,green:245/255,blue:139/255,alpha:1));ctx.setLineWidth(43);ctx.setLineCap(.round);ctx.move(to:CGPoint(x:512,y:451));ctx.addLine(to:CGPoint(x:512,y:269));ctx.strokePath()
 let image=ctx.makeImage()!;let rep=NSBitmapImageRep(cgImage:image);try rep.representation(using:.png,properties:[:])!.write(to:URL(fileURLWithPath:path))
}
for e in entries { let size=Double(e["size"]!.split(separator:"x")[0])!;let scale=Double(e["scale"]!.replacingOccurrences(of:"x",with:""))!;try render(Int(size*scale),assets+"/"+e["filename"]!) }
try render(1024,root+"/design/tutor-bloom-icon.png")
print("Rendered all iOS icon sizes and 1024px preview")

for scale in 1...3 {
 let suffix = scale == 1 ? "" : "@\(scale)x"
 try render(168 * scale, root + "/ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage\(suffix).png")
}
