# Prevent minitest from loading Rails plugins (this is not a Rails project)
ENV["MT_NO_PLUGINS"] = "1" unless ENV.key?("MT_NO_PLUGINS")

require "minitest/autorun"
require "pathname"
require_relative "../lib/njsparser"

# Load test data files
TEST_DATA_DIR = Pathname(__dir__).join("src")

def load_test_file(filename)
  path = TEST_DATA_DIR.join(filename)
  if filename.end_with?(".html")
    File.binread(path.to_s)
  else
    File.read(path.to_s)
  end
end

# Has NextJS (with recent flight data)
NEXTJS_ORG_HTML = load_test_file("nextjs.org.html")

# Has NextJS (with flightdata including a noindex data)
MINTSTARS_COM_HTML = load_test_file("mintstars.com.html")

# Has NextJS (with older flight data) and custom prefix to static paths
SWAG_LIVE_HTML = load_test_file("swag.live.html")

# Build manifest from nextjs (function)
NEXTJS_ORG_4MSOWJPTZZPEMGZZI8AOO_BUILD_MANIFEST = load_test_file("nextjs_org_4mSOwJptzzPemGzzI8AOo_buildManifest.js")

# Build manifest from swag.live (function)
SWAG_LIVE_GIZ3A1H7OUZFXGRHIDMX_BUILD_MANIFEST = load_test_file("swag_live_giz3a1H7OUzfxgxRHIdMx_buildManifest.js")

# Build manifest from app.osint.industries (not function)
APP_OSINT_INDUSTRIES_YAZR27J6CJHLWW3VXUZZI_BUILD_MANIFEST = load_test_file("app_osint_industries_yAzR27j6CjHLWW3VxUzzi_buildManifest.js")

# Build manifest from runpod.io (function with lot of vars)
RUNPOD_IO_S4XE_TFYLTFF_BW1HFD4_BUILD_MANIFEST = load_test_file("runpod_io_s4xe_TFYlTTFF_bw1HfD4_buildManifest.js")

# Has NextJS (with __next_data__)
M_SOUNDCLOUD_COM_HTML = load_test_file("m.soundcloud.com.html")

# Doesn't have NextJS
X_COM_HTML = load_test_file("x.com.html")

# Has nextjs (with flight data, having a rscpayload in a list)
# To test recursive search of elements.
CLUB_FANS_HTML = load_test_file("club.fans.html")
