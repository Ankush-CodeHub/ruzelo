import yt_dlp

def search_live_catalog(query, limit=5):
    ydl_opts = {
        'extract_flat': 'in_playlist',
        'quiet': True,
        'no_warnings': True,
    }
    with yt_dlp.YoutubeDL(ydl_opts) as ydl:
        res = ydl.extract_info(f'ytsearch{limit}:{query}', download=False)
        entries = res.get('entries', [])
        print(f"=== Results for '{query}' ({len(entries)} songs) ===")
        for e in entries:
            print(f"  * {e.get('title')} | Duration: {e.get('duration')}s | ID: {e.get('id')}")

if __name__ == '__main__':
    search_live_catalog('Latest Bollywood Songs 2026', 5)
    search_live_catalog('Punjabi Party Hits 2026', 5)
