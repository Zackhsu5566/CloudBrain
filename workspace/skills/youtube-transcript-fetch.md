---
name: YouTube Transcript Fetch
created: 2026-04-13
last_used: 2026-04-13
use_count: 1
---

## Trigger
When the user sends a YouTube video link and asks for analysis, summary, or content review.

## Steps

### 1. Get Video Metadata
Use YouTube oembed API (no API key needed):
```python
python3 -c "
from urllib.request import urlopen
import json
video_id = 'VIDEO_ID_HERE'
url = f'https://www.youtube.com/oembed?url=https://www.youtube.com/watch?v={video_id}&format=json'
data = json.loads(urlopen(url, timeout=5).read().decode('utf-8'))
print('Title:', data.get('title', ''))
print('Author:', data.get('author_name', ''))
print('Thumbnail:', data.get('thumbnail_url', ''))
"
```

### 2. Try to Get Transcript

**Option A: Third-party transcript sites (preferred)**
Search for: `site:yt.aibeginner.org VIDEO_ID` or `site:recapio.com VIDEO_TITLE`

Or directly try:
```
https://yt.aibeginner.org/transcript-VIDEO_TITLE/
```

**Option B: Web search for transcript**
```web_search
query: "VIDEO_TITLE transcript" or "VIDEO_ID youtube transcript"
```

**Option C: YouTube page fetch (usually returns JS-rendered blank)**
```web_fetch
url: https://youtu.be/VIDEO_ID
```
→ Usually fails with 200 but empty content (requires JS). Not reliable.

**Option D: Invidious alternative frontends**
Try: `https://yewtu.be/watch?v=VIDEO_ID`
Note: Many instances are blocked. Check if working.

### 3. Fetch Full Transcript Page
Once found, use `web_fetch` with `maxChars: 15000` to get full content:
```
web_fetch(url: TRANSCRIPT_URL, maxChars: 15000)
```

### 4. Analyze Content
The transcript text will be timestamped (e.g., `00:00:00 So, you want to...`). Extract the full content and provide analysis.

## Fallbacks if Transcript Unavailable

- Get video description via oembed or search snippet
- Use `web_search` to find third-party summaries/digests
- Note in response: "Full transcript not available, here's what we could find"

## Notes
- YouTube oembed API always works for metadata
- Third-party transcript sites (yt.aibeginner.org, recapio.com) are the most reliable for getting actual video content
- `yt-dlp` is NOT installed on VPS — don't rely on it
- If video is in English, yt.aibeginner.org usually has the transcript
- For non-English videos, success rate varies
