
<#macro updatetquery>
  final String query =<@compress single_line=true>"UPDATE ${table.escapedName?j_string} SET
        		<#assign index=0>
        		<#list updatableProperties as property>
        			<#if property.column.primaryKeyIndex == 0>
        			<#if index == 0><#assign index=1><#else>,</#if>${property.column.escapedName?j_string} = ${getPreparedValue(property,orm.updateMap)}
        			</#if>
        		</#list>

		</@compress>"
+ ( this.whereClause == null ? "" : (" WHERE " + this.whereClause.asSql()) );
</#macro>

<#macro updatewithsetquery>
  final String query = <@compress single_line=true>"UPDATE ${table.escapedName?j_string} SET "+
                getSetValues()
		</@compress>
+ ( this.whereClause == null ? "" : (" WHERE " + this.whereClause.asSql()) );
</#macro>

<#if table.tableType == 'TABLE' >




	public UpdateStatement update() {
        return new UpdateStatement(       
        <#if containsEncryptedProperty() >
            this.encryptionFunction
            ,this.decryptionFunction
        </#if>
        );
    }

    public final class UpdateStatement {
        


        <#if containsEncryptedProperty() >
            private final Function<String,String> encryptionFunction;
            private final Function<String,String> decryptionFunction;
        </#if>

        private UpdateStatement(
        <#if containsEncryptedProperty() >
            final Function<String,String> encryptionFunction
            ,final Function<String,String> decryptionFunction
        </#if>
                ) {
  
            
            <#if containsEncryptedProperty() >
            this.encryptionFunction = encryptionFunction;
            this.decryptionFunction = decryptionFunction;
            </#if>
        }

        private void prepare(final DataManager.SqlBuilder sqlBuilder,final ${name} ${name?uncap_first}) throws SQLException {
            <#assign index=0>
            <#assign column_index=1>
            <#list updatableProperties as property>
                <#if containsProperty(property,orm.updateMap)>
                    <#if property.column.primaryKeyIndex == 0>
                    <#if index == 0><#assign index=1><#else></#if>sqlBuilder.param(${property.name?uncap_first}(${name?uncap_first+"."+property.name + "()"}));
                                                                                <#assign column_index = column_index + 1>
                    </#if>
                </#if>
            </#list>
        }


        public SetByPKClause set(final ${name} ${name?uncap_first}) {
            return new SetByPKClause(${name?uncap_first});
        }

        public final class SetByPKClause  {
    
                private WhereClause whereClause;
                private final ${name} ${name?uncap_first};

                SetByPKClause(final ${name} ${name?uncap_first}) {
                    this.${name?uncap_first} = ${name?uncap_first};
                }

                public SetByPKClause where(final WhereClause whereClause) {
                    this.whereClause = whereClause;
                    return this;
                }


                public int execute() throws SQLException  {
                
                    <@updatetquery/>

                    DataManager.SqlBuilder sqlBuilder = dataManager.sql(query);
                    prepare(sqlBuilder,${name?uncap_first});
                    return sqlBuilder.executeUpdate();
                }

                <#if table.hasPrimaryKey>

                public final ${name} returning() throws <@throwsblock/>  {
                    ${name} updated${name} = null ;
                    <@updatetquery/>
                    DataManager.SqlBuilder sqlBuilder = dataManager.sql(query);
                    prepare(sqlBuilder,${name?uncap_first});
         
                        
                        if( sqlBuilder.executeUpdate() == 1 ) {
                        <#if table.hasAutoGeneratedPrimaryKey == true>
                        
  
                        updated${name} =  select(${getPrimaryKeysFromModel(name?uncap_first)}).get();
                        </#if>
                    }
                    
                    return updated${name};
                }
             </#if>
            }

        public SetClause set(final Value... values) {
            return new SetClause(values);
        }

        public final class SetClause  {
            
            private Value[] values;
        

            SetClause(final Value[] values) {
                this.values = values;
            }

            public SetWhereClause where(WhereClause whereClause) {
                return new SetWhereClause(this, whereClause);
            } 

            public final class SetWhereClause  {
                private final SetClause setClause;
                private WhereClause whereClause;

                SetWhereClause(final SetClause setClause, WhereClause whereClause) {
                    this.setClause = setClause;
                    this.whereClause = whereClause;
                }

                private String getSetValues() {
                    StringBuilder stringBuilder = new StringBuilder();
                    boolean isFirst = true;
                    for (Value value:
                            this.setClause.values) {
                        if(isFirst) {
                            isFirst = false;
                        } else {
                            stringBuilder.append(",");
                        }
                        stringBuilder.append(value.column().name()).append("=?");
                    }
                    return stringBuilder.toString();
                }
                
                public final int execute() throws SQLException  {
                    
                    <@updatewithsetquery/>

                    DataManager.SqlBuilder sqlBuilder = dataManager.sql(query);

                    for (Value value:values) {
                        sqlBuilder.param(value);
                    }

                    return sqlBuilder.executeUpdate();
                }

                public final List<${name}> returning() throws <@throwsblock/>  {
                    return null;
                }
            }
            
        }
        
    public UpdateQuery sql(final String sql) {
        return new UpdateQuery(sql);
    }

    public final class UpdateQuery  {

        private final String sql;
        private final List<Value> values;

        public UpdateQuery(final String sql) {
            this.sql = sql;
            this.values = new ArrayList<>();
        }


        public UpdateQuery param(final Value value) {
            this.values.add(value);
            return this;
        }

        public int execute() throws SQLException {
            DataManager.SqlBuilder sqlBuilder = dataManager.sql(sql);

            for (Value value:values) {
                sqlBuilder.param(value);
            }
            
            return sqlBuilder.executeUpdate();
        }


    }


    }	
</#if>


