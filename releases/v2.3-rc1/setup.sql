
exec sash_repo.add_db('&HOST1', 1521, 'sash', 'datag', '&INST1',1, '11.2.0.2', 8);                                                                                                                      

exec sash_pkg.configure_db('datag1');                                                                                                                                                                   

exec sash_pkg.set_dbid('datag1');                                                                                                                                                                       

exec sash_repo.setup_jobs                                                                                                                                                                               

exec sash_repo.start_collecting_jobs                                                                                                                                                                    

exec sash_repo.purge                                                                                                                                                                                    
