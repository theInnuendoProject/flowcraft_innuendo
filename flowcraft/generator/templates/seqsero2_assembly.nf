process seqsero2_assembly_{{ pid }} {
    // Send POST request to platform
    {% include "post.txt" ignore missing %}

    tag { sample_id }
    errorStrategy { task.exitStatus == 120 ? 'ignore' : 'ignore' }
    publishDir path: "results/typing/seqsero2_assembly/${sample_id}/", mode: 'symlink', overwrite: true, pattern: 'Seq*.txt'

    input:
    set sample_id, file(fasta) from {{ input_channel }}

    output:
    file "Seq*.txt"
    {% with task_name="seqsero2_assembly" %}
    {%- include "compiler_channels.txt" ignore missing -%}
    {% endwith %}

    script:
    """
    exit_code=0

    version_str="[{'program':'SeqSero2_package.py','version':'$task.container'}]"
    echo \$version_str > .versions

    status='error'
    report_str="{'tableRow':[{'sample':'${sample_id}','data':[{'header':'seqsero2_assembly','value':'NA','table':'typing'}]}]}"

    {
      SeqSero2_package.py -m k -p $task.cpus -t 4 -i ${fasta[0]} -d ./seqsero2_out/
    } || {
      exit_code=\$?
    }

    if [ \$exit_code -eq 0 ]; then
      status='pass'

      mv ./seqsero2_out/* ./

      sero=\$(grep \'Predicted serotype(s):\' ./Seqsero_result.txt | cut -f 2)
      if [ \$(echo \$sero | grep '^N/A' | wc -l) -gt 0 ]; then
        sero='ND'
      fi

      report_str="{'tableRow':[{'sample':'${sample_id}','data':[{'header':'seqsero2_assembly','value':'\$sero','table':'typing'}]}]}"
    fi

    echo \$status > .status
    echo \$report_str > .report.json

    exit \$exit_code
    """
}

{{ forks }}
