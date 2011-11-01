
exec sash_repo.add_db('&HOST1', 1521, 'sash', 'racdb', 'racdb1',1, '11.2.0.2', 8);                                                                                                                      
exec sash_repo.add_db('&HOST2', 1521, 'sash', 'racdb', 'racdb2',2, '11.2.0.2', 8);                                                                                                                      
exec sash_repo.add_db('&HOST3', 1521, 'sash', 'racdb', 'racdb3',3, '11.2.0.2', 8);                                                                                                                      

exec sash_pkg.configure_db('racdb1');                                                                                                                                                                   

exec sash_pkg.set_dbid('racdb1');                                                                                                                                                                       

exec sash_repo.setup_jobs                                                                                                                                                                               

exec sash_repo.start_collecting_jobs                                                                                                                                                                    

exec sash_repo.purge                                                                                                                                                                                    
