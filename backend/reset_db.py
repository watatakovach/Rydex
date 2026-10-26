from pathlib import Path
p = Path('rydex.db')
if p.exists(): p.unlink()
print('RYDEX database removed. Restart the server to recreate it.')
