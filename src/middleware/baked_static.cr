require "baked_file_system"
require "mime-types"

class BakedStatic
  BakedFileSystem.load("../../public", __DIR__)
  include HTTP::Handler

  def call(context)
  call_next context
    file = self.class.get(context.request.path)
    context.response.headers["content-type"] = MIME::Types.type_for(context.request.path).to_a[0]?.to_s
    file.write_to_io(context.response, false)
  rescue BakedFileSystem::NoSuchFileError
    call_next context
  end
end
