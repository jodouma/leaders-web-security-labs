def search_products(cursor, query: str):
    """Remplacer la concaténation par un paramètre du driver."""
    sql = "SELECT id,name FROM products WHERE name ILIKE '%" + query + "%'"
    cursor.execute(sql)
    return cursor.fetchall()
