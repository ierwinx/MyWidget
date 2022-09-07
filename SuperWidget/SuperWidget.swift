import WidgetKit
import SwiftUI

// MARK: - Model
struct SuperWidgetModel: TimelineEntry {
    let date: Date
    let strImage: String
    let posts: [PostModel]
}

struct PostModel: Decodable {
    let id: Int
    let title: String
    let body: String
}


// MARK: - Provider
struct SuperWidgetProvider: TimelineProvider {
    
    typealias Entry = SuperWidgetModel
    
    func placeholder(in context: Context) -> SuperWidgetModel {
        return SuperWidgetModel(date: Date(), strImage: "person.fill", posts: [])
    }
    
    func getSnapshot(in context: Context, completion: @escaping (SuperWidgetModel) -> Void) {
        completion(SuperWidgetModel(date: Date(), strImage: "person.fill", posts: []))
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<SuperWidgetModel>) -> Void) {
        
        PostNetwork.getDataPost { arrPost, error in
            
            let handlerError = Timeline(entries: [SuperWidgetModel(date: Date(), strImage: "error", posts: [])], policy: .never)
            
            guard error.code == 0 else {
                completion(handlerError)
                return
            }
            
            guard let updateWidget = Calendar.current.date(byAdding: .minute, value: 2, to: Date()) else { // se actualizara cada 2 minutos
                completion(handlerError)
                return
            }
            
            completion(Timeline(entries: [SuperWidgetModel(date: Date(), strImage: "person.fill", posts: arrPost)], policy: .after(updateWidget)))
        }
        
    }
    
}

class PostNetwork {
    static func getDataPost(completion: @escaping ([PostModel], NSError) -> ()) {
        DispatchQueue.global(qos: .utility).async {
            guard let endpoint: URL = URL(string: "https://jsonplaceholder.typicode.com/posts") else {
                return
            }
            var request = URLRequest(url: endpoint)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpMethod = "GET"
            let tarea = URLSession.shared.dataTask(with: request) { data, response, error in
                DispatchQueue.main.sync {
                    if let errorNS = error as NSError? {
                        completion([], errorNS)
                    }
                    guard let dataRes = data, let objRes = try? JSONDecoder().decode([PostModel].self, from: dataRes) else {
                        completion([], NSError(domain: "Posts.getData.errorParse", code: -1, userInfo: nil))
                        return
                    }
                    completion(objRes, NSError(domain: "exito", code: 0, userInfo: nil))
                }
            }
            tarea.resume()
        }
    }
}

// MARK: - View
struct SuperWidgetEntryView : View {
    
    var entry: SuperWidgetProvider.Entry
    
    @Environment(\.widgetFamily) var widgetFamily

    var body: some View {
        VStack {
            if widgetFamily == .systemSmall {
                Image(systemName: entry.strImage)
                    .resizable()
                    .scaledToFit()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 50, height: 50, alignment: .center)
                    .foregroundColor(.red)
                
                Text(entry.date, style: .time)
                    .bold()
            }
            
            if widgetFamily == .systemMedium {
                Text("Diseño mediano")
                    .font(.largeTitle)
                    .bold()
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.white)
                    .background(.red)
                Spacer()
                
                Text("\(entry.posts.count)")
                    .font(.custom("Arial", size: 80))
                    .bold()
                
                Spacer()
            }
            
            if widgetFamily == .systemLarge {
                ForEach(entry.posts, id: \.id) { post in
                    Text(post.title)
                }
            }
            
        }
    }
    
}

// MARK: - Widget
@main
struct SuperWidget: Widget {
    
    let kind: String = "SuperWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SuperWidgetProvider()) { entry in
            SuperWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("My Widget")
        .description("This is an example widget.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
    
}

struct SuperWidget_Previews: PreviewProvider {
    static var previews: some View {
        SuperWidgetEntryView(entry: SuperWidgetModel(date: Date(), strImage: "person.fill", posts: []))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}
